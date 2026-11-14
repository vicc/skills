#!/usr/bin/env python3
"""Collect aggregate Codex skill evidence. Reads local sources without changing them."""
import argparse
from collections import Counter, defaultdict
from contextlib import contextmanager
from datetime import datetime
import hashlib
import io
import json
import multiprocessing as mp
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib
from functools import lru_cache

SESSION_ID = re.compile(r"([a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12})\.jsonl(?:\.zst)?$")
CATALOG_ITEM = re.compile(r"^- (.+?): .*?\(file: (.+?/SKILL\.md)\)\s*$")
SHELL_PATH = re.compile(r"(?:[~\w.*{}$+@()-]+/)+SKILL\.md")
NAME = re.compile(r"(?m)^name:\s*['\"]?([\w.:-]+)")
READ = re.compile(r"\b(cat|sed|head|tail|bat|awk|less|more|Get-Content|read_file|readFileSync|readFile|open|read_text|read_bytes)\b")
LOOKUP = re.compile(r"\b(ls|find|rg|grep|stat|test|shasum|cp|mv|rm|mkdir|touch|write_text|writeFile|apply_patch)\b")
SKILL_TOOL = re.compile(r"skills__read|skill_read|skills\.read")
SIGNAL = re.compile(rb"session_meta|turn_context|task_started|turn_started|function_call|custom_tool_call")
PAGE = 350


@contextmanager
def session_lines(path):
    if path.suffix != ".zst":
        with path.open("rb") as stream:
            yield stream
        return
    try:
        from compression import zstd
    except ImportError:
        zstd = None
    if zstd is not None:
        with zstd.open(path, "rb") as stream:
            yield stream
        return
    try:
        import zstandard
    except ImportError:
        zstandard = None
    if zstandard is not None:
        with path.open("rb") as source, zstandard.ZstdDecompressor().stream_reader(source) as reader:
            with io.BufferedReader(reader, 1 << 20) as stream:
                yield stream
        return
    command = shutil.which("zstd")
    if not command:
        raise OSError("No Zstandard reader")
    with subprocess.Popen([command, "-dc", "--", str(path)], stdout=subprocess.PIPE,
                          stderr=subprocess.DEVNULL) as process:
        yield process.stdout
        if process.wait():
            raise OSError("Could not read compressed session")


def sessions(codex_home):
    files = {}
    for suffix in ("*.jsonl", "*.jsonl.zst"):
        for folder in ("sessions", "archived_sessions"):
            for path in sorted((codex_home / folder).rglob(suffix)):
                if match := SESSION_ID.search(path.name):
                    files.setdefault(match[1], path)
    return files


def path_of(raw, home):
    return home / raw[2:] if raw.startswith("~/") else Path(raw)


def metadata(path, home):
    if path is None:
        return {}, None, None, None
    catalog = {}
    block = window = date = None
    try:
        with session_lines(path) as lines:
            for raw in lines:
                if b"<skills_instructions>" not in raw and b'"type":"token_count"' not in raw:
                    continue
                try:
                    data = json.loads(raw)
                except ValueError:
                    continue
                item = data.get("payload") or {}
                if window is None and item.get("type") == "token_count":
                    reported = (item.get("info") or {}).get("model_context_window")
                    if isinstance(reported, int) and reported > 0:
                        window = reported
                if block is None and data.get("type") == "response_item" and item.get("role") == "developer":
                    for part in item.get("content", []):
                        content = part.get("text", "")
                        match = re.search(r"<skills_instructions>.*?</skills_instructions>", content, re.S)
                        if match and "### Available skills" in match[0]:
                            block = match[0]
                            date = data.get("timestamp")
                            roots = dict(re.findall(r"^- \x60(r\d+)\x60 = \x60([^\x60]+)\x60", block, re.M))
                            for line in block.splitlines():
                                if entry := CATALOG_ITEM.match(line):
                                    token, _, rest = entry[2].partition("/")
                                    location = Path(roots[token]) / rest if token in roots else path_of(entry[2], home)
                                    catalog[line] = (entry[1], location)
                if block is not None and window is not None:
                    # A compressed command needs its stream consumed only when
                    # scanning history. Avoid prematurely closing its pipe here.
                    if path.suffix != ".zst":
                        break
    except (OSError, EOFError):
        pass
    if block is not None and not catalog and re.search(r"^-\s+\S+:", block.split("### Available skills", 1)[-1], re.M):
        return {}, None, None, date
    return catalog, block, window, date


def plugin_path(path):
    parts = path.parts
    try:
        index = parts.index("cache", parts.index("plugins") + 1)
        return parts[index + 1], parts[index + 2], parts[index + 3], path.parent.name
    except (ValueError, IndexError):
        return None


def skill_id(path, home, codex_home):
    plugin = plugin_path(path)
    if plugin:
        return f"{plugin[1]}:{plugin[3]}"
    for root, label in ((codex_home / "skills/.system", "built-in"),
                        (codex_home / "skills", "local"), (home / ".agents/skills", "agents")):
        if path.is_relative_to(root):
            return f"{label}:{path.parent.name}"
    return f"project:{path.parent.name}@{hashlib.sha256(str(path.parent).encode()).hexdigest()[:8]}"


def inventory(catalog, historical_catalog, args):
    try:
        with (args.codex_home / "config.toml").open("rb") as file:
            config = tomllib.load(file)
    except (FileNotFoundError, tomllib.TOMLDecodeError):
        config = {}
    disabled = {str(path_of(entry["path"], args.home)) for entry in (config.get("skills") or {}).get("config", [])
                if "path" in entry and entry.get("enabled") is False}
    active = {value[:3] for _, path in catalog.values() if (value := plugin_path(path))}
    current_plugins = {value[:2] for value in active}
    for _, path in historical_catalog.values():
        if path.is_file() and (value := plugin_path(path)) and value[:2] not in current_plugins:
            active.add(value[:3])
    cache = args.codex_home / "plugins/cache"
    for key, settings in config.get("plugins", {}).items():
        if "@" not in key or settings.get("enabled") is not True:
            continue
        plugin, market = key.split("@", 1)
        directory = cache / market / plugin
        if directory.is_dir() and not any(item[:2] == (market, plugin) for item in active):
            versions = [path for path in directory.iterdir() if (path / "skills").is_dir()]
            if versions:
                version = max(versions, key=lambda path: (path.stat().st_mtime, path.name))
                active.add((market, plugin, version.name))
    found = {}

    def add(name, path, available):
        key = skill_id(path, args.home, args.codex_home)
        if key not in found:
            owner = "plugin" if plugin_path(path) else ("built-in" if key.startswith("built-in:") else "standalone")
            found[key] = {"id": key, "name": name, "path": str(path), "owner": owner,
                          "in_catalog": available, "disabled": str(path) in disabled, "on_disk": path.is_file()}

    for name, path in catalog.values():
        add(name, path, True)
    for name, path in historical_catalog.values():
        if path.is_file():
            add(name, path, False)
    roots = [(args.home / ".agents/skills"), (args.codex_home / "skills"), (args.codex_home / "skills/.system")]
    if args.workspace:
        roots.extend([args.workspace / ".agents/skills", args.workspace / ".codex/skills"])
    for root in roots:
        for path in sorted(root.glob("*/SKILL.md")):
            add(path.parent.name, path, False)
    for market, plugin, version in sorted(active):
        for path in sorted((cache / market / plugin / version / "skills").glob("*/SKILL.md")):
            add(f"{plugin}:{path.parent.name}", path, False)
    return found


def configure_scan(rows, home, codex_home):
    global SCAN_ROWS, SCAN_HOME, SCAN_CODEX, SCAN_SLUGS
    SCAN_ROWS, SCAN_HOME, SCAN_CODEX = rows, home, codex_home
    SCAN_SLUGS = defaultdict(set)
    for key, row in rows.items():
        SCAN_SLUGS[Path(row["path"]).parent.name].add(key)


def resolve(raw):
    path = path_of(raw, SCAN_HOME)
    key = skill_id(path, SCAN_HOME, SCAN_CODEX)
    if key in SCAN_ROWS:
        return key
    if plugin_path(path):
        return None
    choices = SCAN_SLUGS.get(path.parent.name, ())
    if len(choices) == 1:
        return next(iter(choices))
    return None


def as_text(content):
    return content if isinstance(content, str) else json.dumps(content, ensure_ascii=False)


@lru_cache(maxsize=512)
def instruction_lines(path):
    try:
        lines = Path(path).read_text(errors="replace").splitlines()
    except OSError:
        return []
    return [line for raw in lines[2:80] if len(line := raw.strip()) > 55
            and not line.startswith(("description:", "<!--"))]


def scan(entry):
    tid, path = entry
    calls = {}
    evidence = set()
    parent = fork = first = last = None
    turn = "unsegmented"
    try:
        with session_lines(path) as lines:
            for raw in lines:
                if not SIGNAL.search(raw, 0, 170) and not (b'"role":"user"' in raw[:420] and b"<skill>" in raw):
                    continue
                output = b"_call_output" in raw[:175]
                if output and not calls:
                    continue
                if b'_call",' in raw[:175] and b"SKILL.md" not in raw and b"skill" not in raw:
                    continue
                try:
                    item = json.loads(raw)
                except ValueError:
                    continue
                payload = item.get("payload") or {}
                ts = item.get("timestamp") or payload.get("timestamp")
                if not ts:
                    continue
                first = first or ts
                last = max(last or ts, ts)
                typ, kind = item.get("type"), payload.get("type")
                if typ == "session_meta" and payload.get("id") == tid:
                    source = payload.get("source")
                    sub = source.get("subagent") if isinstance(source, dict) else None
                    spawn = sub.get("thread_spawn") if isinstance(sub, dict) else None
                    parent = payload.get("parent_thread_id") or (spawn.get("parent_thread_id") if isinstance(spawn, dict) else None)
                    fork = payload.get("forked_from_id")
                if typ == "turn_context" or typ == "event_msg" and kind in ("task_started", "turn_started"):
                    turn = payload.get("turn_id") or (ts if typ == "event_msg" else turn)
                if typ != "response_item":
                    continue
                if kind == "message" and payload.get("role") == "user":
                    for part in payload.get("content", []):
                        for match in re.finditer(r"<skill>\s*<name>[^<]+</name>\s*<path>([^<]+)</path>", part.get("text", "")):
                            if key := resolve(match[1].strip()):
                                evidence.add((key, turn, ts))
                call_id = payload.get("call_id")
                if kind in ("function_call", "custom_tool_call") and call_id:
                    arg = as_text(payload.get("input") or payload.get("arguments") or "")
                    skill_reader = SKILL_TOOL.search(str(payload.get("name", "")) + " " + arg)
                    if not skill_reader and ("SKILL.md" not in arg or not READ.search(arg)):
                        continue
                    paths = {}
                    for match in SHELL_PATH.finditer(arg):
                        prefix = arg[max(0, match.start() - 400):match.start()]
                        command = re.split(r";|&&|\|\||\n|\\n", prefix)[-1]
                        loop_read = not LOOKUP.search(command) and re.search(r"\bfor\b", prefix) and READ.search(prefix)
                        if (READ.search(command) or skill_reader or loop_read) and (key := resolve(match[0])):
                            paths[key] = match[0]
                    if skill_reader and not paths:
                        for key, row in SCAN_ROWS.items():
                            if re.search(r"(?<![\w-])" + re.escape(row["name"]) + r"(?![\w-])", arg):
                                paths[key] = row["path"]
                    calls[call_id] = (turn, ts, paths)
                elif output and call_id in calls:
                    called_turn, called_at, paths = calls.pop(call_id)
                    result = as_text(payload.get("output") or payload.get("content") or "")
                    result = result.replace("\\n", "\n").replace('\\"', '"')
                    if payload.get("is_error") or re.search(r'"isError":\s*true', result[:800]):
                        continue
                    headers = {name.lower() for name in NAME.findall(result)}
                    for key in paths:
                        slug = Path(SCAN_ROWS[key]["path"]).parent.name
                        if slug.lower() in headers:
                            evidence.add((key, called_turn, called_at))
                    if len(paths) == 1 and not re.search(
                            r'(?:exited with code|exit_code["\']?\s*:)\s*[1-9]|No such file|Permission denied|"timed_out"\s*:\s*true',
                            result):
                        key = next(iter(paths))
                        body = re.split(r"(?:^|\n)(?:Output:|Final output:)\s*\n", result, maxsplit=1)[-1]
                        if any(line in body for line in instruction_lines(SCAN_ROWS[key]["path"])):
                            evidence.add((key, called_turn, called_at))
                    if not paths or any("*" in value or "$" in value for value in paths.values()):
                        for header in headers:
                            matches = SCAN_SLUGS.get(header, ())
                            if len(matches) == 1:
                                evidence.add((next(iter(matches)), called_turn, called_at))
    except (EOFError, OSError) as error:
        return tid, parent, fork, first, last, evidence, type(error).__name__
    except Exception as error:
        if type(error).__name__ != "ZstdError":
            raise
        return tid, parent, fork, first, last, evidence, type(error).__name__
    return tid, parent, fork, first, last, evidence, None


def usage(files, rows, args, exclude):
    selected = [(key, path) for key, path in files.items() if key != exclude]
    selected.sort(key=lambda value: value[1].stat().st_size, reverse=True)
    scanned = []
    if selected:
        with mp.Pool(min(8, os.cpu_count() or 1), configure_scan, (rows, args.home, args.codex_home)) as pool:
            scanned = list(pool.imap_unordered(scan, selected, chunksize=8))
    lineage = {record[0]: record[1] for record in scanned}

    def parent_chat(tid):
        visited = set()
        while lineage.get(tid) and tid not in visited:
            visited.add(tid)
            tid = lineage[tid]
        return tid

    recovered = [record for record in scanned if record[3]]
    matches = defaultdict(set)
    latest = {}
    taken = set()
    for tid, parent, fork, first, last, evidence, error in sorted(scanned, key=lambda r: (bool(r[1] or r[2]), r[0])):
        for key, turn, at in sorted(evidence):
            copy_key = (key, at)
            if copy_key not in taken:
                matches[key].add((parent_chat(tid), tid, turn))
                taken.add(copy_key)
                latest[key] = max(latest.get(key, at), at)
    for key, row in rows.items():
        row.update(chats=len({item[0] for item in matches[key]}) if recovered else None,
                   turns=len(matches[key]) if recovered else None,
                   last_used_at=latest.get(key))
    return {"scanned": len(recovered), "skipped_or_partial": sum(not r[3] or bool(r[6]) for r in scanned),
            "first": min((r[3] for r in recovered), default=None),
            "last": max((r[4] for r in recovered), default=None)}


def duplicate_leads(rows):
    documents = {}
    for key, row in rows.items():
        try:
            raw = Path(row["path"]).read_bytes()
        except OSError:
            continue
        content = raw.decode(errors="replace").lower()
        terms = re.findall(r"[\w-]+", content)
        shingles = set(zip(terms, terms[1:], terms[2:]))
        documents[key] = (hashlib.sha256(raw).digest(), shingles)
    leads = []
    for key, row in rows.items():
        if row["chats"] != 0 or key not in documents:
            continue
        digest, words = documents[key]
        for other, (other_digest, other_words) in documents.items():
            if key == other:
                continue
            same_name = Path(row["path"]).parent.name == Path(rows[other]["path"]).parent.name
            similarity = len(words & other_words) / max(1, len(words | other_words))
            if digest == other_digest or same_name or similarity >= 0.45:
                leads.append({"id": key, "replacement": other, "same_name": same_name,
                              "identical_file": digest == other_digest, "text_similarity": round(similarity, 2)})
    return sorted(leads, key=lambda row: (row["id"], -row["text_similarity"], row["replacement"]))


def scan_references(rows, ids, args):
    scope = [args.home / ".agents/skills", args.codex_home / "skills", args.codex_home / "AGENTS.md"]
    if args.workspace:
        scope.append(args.workspace)
    candidates = {key: Path(rows[key]["path"]) for key in ids}
    patterns = {key: re.compile(r"(?<![\w-])" + re.escape(path.parent.name) + r"(?![\w-])")
                for key, path in candidates.items()}
    matches = {key: [] for key in ids}
    examined = inaccessible = 0
    files = {Path(row["path"]) for row in rows.values() if row["owner"] == "plugin" and row["on_disk"]}
    for root in scope:
        if root.is_file():
            files.add(root)
            continue
        for directory, folders, names in os.walk(root):
            folders[:] = [name for name in folders if name not in {".git", "node_modules", "build", "dist", "work", "outputs", ".venv"}]
            for name in names:
                path = Path(directory) / name
                if path.suffix.lower() in {".md", ".toml", ".yaml", ".yml", ".json", ".sh", ".py"}:
                    files.add(path)
    for path in sorted(files):
        try:
            if path.is_symlink() or path.stat().st_size > 2_000_000:
                inaccessible += 1
                continue
            content = path.read_text(errors="replace")
        except OSError:
            inaccessible += 1
            continue
        examined += 1
        for key, pattern in patterns.items():
            candidate = candidates[key]
            if path.is_relative_to(candidate.parent):
                continue
            for hit in pattern.finditer(content):
                matches[key].append({"file": str(path), "line": content.count("\n", 0, hit.start()) + 1})
    return {"scope": [str(root) for root in scope] + ["Inventoried plugin SKILL.md files"], "files_examined": examined,
            "files_skipped": inaccessible, "matches": matches}


def measure(block, catalog, window, date, rows, candidates, args):
    metrics = {"catalog_count": len(catalog) if block is not None else None, "estimated_tokens": None,
               "window_tokens": window, "window_percent": None, "double_spaced_pages": None,
               "snapshot_at": date, "combined_savings": None, "combined_savings_pages": None,
               "candidate_savings": {key: None for key in candidates}, "encoding": None,
               "unavailable_reason": None}
    if block is None:
        metrics["unavailable_reason"] = "No matching startup catalog"
        return metrics
    runtime = Path(__file__).resolve().parents[1] / ".local-runtime"
    if (runtime / "python").is_dir():
        sys.path.append(str(runtime / "python"))
    if (runtime / "cache").is_dir():
        os.environ.setdefault("TIKTOKEN_CACHE_DIR", str(runtime / "cache"))
    try:
        import tiktoken
        import tiktoken.load

        def offline_file(path):
            raise OSError(f"Tokenizer encoding data is not cached: {path}")

        read_file = tiktoken.load.read_file_cached

        def cached_file(path, expected_hash=None):
            configured = os.environ.get("TIKTOKEN_CACHE_DIR", os.environ.get("DATA_GYM_CACHE_DIR"))
            if configured is None:
                import tempfile
                configured = str(Path(tempfile.gettempdir()) / "data-gym-cache")
            if not configured:
                return offline_file(path)
            data = (Path(configured) / hashlib.sha1(path.encode()).hexdigest()).read_bytes()
            if expected_hash and hashlib.sha256(data).hexdigest() != expected_hash:
                raise OSError("Tokenizer encoding cache failed its integrity check")
            return data

        tiktoken.load.read_file_cached = cached_file
        try:
            encoder = tiktoken.get_encoding("o200k_base")
        finally:
            tiktoken.load.read_file_cached = read_file
    except (ImportError, OSError):
        metrics["unavailable_reason"] = "Local o200k_base tokenizer or encoding data unavailable"
        return metrics
    count = lambda content: len(encoder.encode_ordinary(content))
    baseline = count(block)
    remove = {}
    for line, (_, path) in catalog.items():
        key = skill_id(path, args.home, args.codex_home)
        if key in rows:
            remove.setdefault(key, set()).add(line)

    def savings(keys):
        excluded = set().union(*(remove.get(key, set()) for key in keys))
        return baseline - count("".join(line for line in block.splitlines(keepends=True) if line.rstrip("\r\n") not in excluded))

    combined = savings(candidates) if candidates else None
    metrics.update(encoding="o200k_base", estimated_tokens=baseline, double_spaced_pages=round(baseline / PAGE, 1),
                   window_percent=round(baseline / window * 100, 2) if window else None,
                   candidate_savings={key: savings([key]) for key in candidates},
                   combined_savings=combined, combined_savings_pages=round(combined / PAGE, 1) if combined is not None else None)
    return metrics


def main():
    sys.dont_write_bytecode = True
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--codex-home", type=Path)
    parser.add_argument("--workspace", type=Path)
    parser.add_argument("--startup-session", type=Path)
    parser.add_argument("--inventory-session", type=Path, help="Older same-scope catalog used only to locate files")
    parser.add_argument("--no-startup", action="store_true")
    parser.add_argument("--from-audit", type=Path, help="Reuse a prior inventory and usage scan")
    parser.add_argument("--candidate", action="append", default=[], help="Verified removal candidate ID")
    parser.add_argument("--check-reference", action="append", default=[], help="Find inbound references for this ID")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    args.home = args.home.expanduser().resolve()
    args.codex_home = (args.codex_home or Path(os.environ.get("CODEX_HOME") or (args.home / ".codex"))).expanduser().resolve()
    if args.workspace:
        args.workspace = args.workspace.expanduser().resolve()
    if args.no_startup and args.startup_session:
        parser.error("--no-startup and --startup-session are mutually exclusive")
    files = sessions(args.codex_home)
    active = os.environ.get("CODEX_THREAD_ID") or os.environ.get("CODEX_SESSION_ID")
    startup = None if args.no_startup else args.startup_session or files.get(active)
    catalog, block, window, date = metadata(startup, args.home)
    historical, _, _, inventory_date = metadata(args.inventory_session, args.home)
    if args.from_audit:
        result = json.loads(args.from_audit.read_text())
        rows = {row["id"]: row for row in result["skills"]}
        for row in rows.values():
            row["in_catalog"] = False
        for _, path in catalog.values():
            if (key := skill_id(path, args.home, args.codex_home)) in rows:
                rows[key]["in_catalog"] = True
    else:
        rows = inventory(catalog, historical, args)
        match = SESSION_ID.search(startup.name) if startup else None
        scope = "Local skill folders and enabled plugin releases visible in local configuration"
        if catalog:
            scope += ", plus the startup catalog"
        if historical:
            scope += ", plus files still on disk from the dated inventory catalog"
        result = {
            "inventory_scope": scope,
            "inventory_catalog_at": inventory_date,
            "usage": usage(files, rows, args, active or (match[1] if match else None)),
        }
        result["duplicate_leads"] = duplicate_leads(rows)
    ids = set(args.candidate + args.check_reference)
    if unknown := ids - rows.keys():
        parser.error("Unknown skill IDs: " + ", ".join(sorted(unknown)))
    result["skills"] = sorted(rows.values(), key=lambda row: (-(row["chats"] or 0), -(row["turns"] or 0), row["name"]))
    result["installed_count"] = sum(row["on_disk"] for row in rows.values())
    result["top_10"] = [row for row in result["skills"] if row["chats"]][:10]
    result["startup"] = measure(block, catalog, window, date, rows, args.candidate, args)
    result["references"] = scan_references(rows, sorted(ids), args) if ids else None
    data = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.write_text(data)
    else:
        print(data, end="")


if __name__ == "__main__":
    main()
