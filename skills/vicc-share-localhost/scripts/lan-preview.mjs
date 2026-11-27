import { execFileSync } from 'node:child_process';
import { request as requestHttp, createServer } from 'node:http';
import { request as requestHttps } from 'node:https';
import { randomUUID } from 'node:crypto';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { isIPv4 } from 'node:net';
import { networkInterfaces, tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { setTimeout as delay } from 'node:timers/promises';

const script = fileURLToPath(import.meta.url);
const labelPrefix = 'com.openai.codex.lan-preview.';
const launchctl = '/bin/launchctl';

function isLoopback(hostname) {
  return hostname === 'localhost' || hostname === '[::1]' ||
    (isIPv4(hostname) && hostname.startsWith('127.'));
}

function requestFor(url) {
  return url.protocol === 'https:' ? requestHttps : requestHttp;
}

function privateIPv4(address) {
  if (!isIPv4(address)) return false;
  const [first, second] = address.split('.').map(Number);
  return first === 10 || (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168);
}

function lanInterface(bind) {
  const available = Object.entries(networkInterfaces()).flatMap(([name, interfaces]) =>
    interfaces.filter(item => !item.internal && privateIPv4(item.address) && validNetmask(item.netmask))
      .map(item => ({ ...item, name })));
  if (bind) {
    const selected = available.find(item => item.address === bind);
    if (!selected) throw new Error('--bind must be a private IPv4 address assigned to this Mac.');
    return selected;
  }

  let defaultInterface;
  try {
    const route = execFileSync('/sbin/route', ['-n', 'get', 'default'], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'],
    });
    defaultInterface = route.match(/interface:\s+(\S+)/)?.[1];
  } catch {
    // A Wi-Fi network can work without a default route.
  }

  const physical = available.filter(item => /^en\d+$/.test(item.name));
  const preferred = physical.filter(item => item.name === defaultInterface);
  if (preferred.length === 1) return preferred[0];
  if (physical.length === 1) return physical[0];

  const choices = available.map(({ name, address }) => `${name} ${address}`).join(', ');
  throw new Error(choices ? `Select the LAN address with --bind. Available: ${choices}` :
    'This Mac has no private IPv4 address available for the preview.');
}

function ipv4Number(address) {
  return address.split('.').reduce((number, octet) => (number << 8) | Number(octet), 0);
}

function validNetmask(mask) {
  if (!isIPv4(mask)) return false;
  const hostBits = ~ipv4Number(mask);
  return hostBits !== -1 && (hostBits & (hostBits + 1)) === 0;
}

function hopHeaders(input) {
  const headers = { ...input };
  const connection = String(headers.connection ?? '').toLowerCase().split(',').map(item => item.trim());
  for (const name of [...connection, 'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization',
    'proxy-connection', 'te', 'trailer', 'transfer-encoding', 'upgrade']) {
    delete headers[name];
  }
  return headers;
}

function runProxy(configPath) {
  const { target, host, netmask, port, ready, caFile } = JSON.parse(readFileSync(configPath, 'utf8'));
  const source = new URL(target);
  const upstreamHost = source.hostname.replace(/^\[|\]$/g, '');
  const upstreamRequest = requestFor(source);
  const upstreamPort = source.port || (source.protocol === 'https:' ? 443 : 80);
  const ca = caFile ? readFileSync(caFile) : undefined;
  const mask = ipv4Number(netmask);
  const subnet = ipv4Number(host) & mask;
  let authority;
  let publicOrigin;

  function validIncoming(incoming) {
    const peer = incoming.socket.remoteAddress;
    const { origin, 'sec-fetch-site': fetchSite, 'sec-fetch-mode': fetchMode } = incoming.headers;
    const navigation = fetchMode === 'navigate' && ['GET', 'HEAD'].includes(incoming.method);
    return privateIPv4(peer) && (ipv4Number(peer) & mask) === subnet &&
      incoming.headers.host === authority && (!origin || origin === publicOrigin) &&
      (fetchSite !== 'cross-site' || navigation) &&
      incoming.url?.startsWith('/') && !incoming.url.startsWith('//');
  }

  function upstreamOptions(incoming) {
    const headers = hopHeaders(incoming.headers);
    for (const name of Object.keys(headers)) {
      if (name === 'forwarded' || name.startsWith('x-forwarded-')) delete headers[name];
    }
    headers.host = source.host;
    if (headers.origin === publicOrigin) headers.origin = source.origin;
    return { hostname: upstreamHost, port: upstreamPort, method: incoming.method, path: incoming.url, headers, ca, rejectUnauthorized: true };
  }

  const server = createServer((incoming, response) => {
    if (!validIncoming(incoming)) {
      response.writeHead(403).end('Use the preview address from its local network.');
      return;
    }
    const upstream = upstreamRequest(upstreamOptions(incoming), reply => {
      const headers = hopHeaders(reply.headers);
      if (headers.location && /^(https?:)?\/\//i.test(headers.location)) {
        try {
          const redirect = new URL(headers.location, source);
          if (redirect.protocol === source.protocol && isLoopback(redirect.hostname) &&
              redirect.port === source.port) {
            headers.location = publicOrigin + redirect.pathname + redirect.search + redirect.hash;
          }
        } catch {
          // Leave an invalid Location to the browser.
        }
      }
      response.writeHead(reply.statusCode, headers);
      reply.on('error', () => response.destroy());
      reply.pipe(response);
    });
    upstream.on('error', () => {
      if (response.headersSent) response.destroy();
      else response.writeHead(502).end('The source preview is unavailable. Check that the app is running on the Mac at its original address, then reload this page.');
    });
    response.on('close', () => upstream.destroy());
    incoming.pipe(upstream);
  });

  server.on('upgrade', (incoming, client, pendingClientData) => {
    if (!validIncoming(incoming) || incoming.headers.upgrade?.toLowerCase() !== 'websocket') {
      client.once('error', () => client.destroy());
      client.end('HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n');
      return;
    }
    const options = upstreamOptions(incoming);
    options.headers.connection = 'Upgrade';
    options.headers.upgrade = incoming.headers.upgrade;
    const upstream = upstreamRequest(options);
    client.on('error', () => upstream.destroy());
    client.on('close', () => upstream.destroy());
    upstream.on('error', () => client.destroy());
    upstream.on('response', reply => {
      reply.resume();
      client.end(`HTTP/1.1 ${reply.statusCode} Upgrade Rejected\r\nConnection: close\r\n\r\n`);
    });
    upstream.on('upgrade', (reply, socket, pendingUpstreamData) => {
      const lines = ['HTTP/1.1 101 Switching Protocols'];
      for (let i = 0; i < reply.rawHeaders.length; i += 2) {
        lines.push(`${reply.rawHeaders[i]}: ${reply.rawHeaders[i + 1]}`);
      }
      socket.on('error', () => client.destroy());
      socket.on('close', () => client.destroy());
      client.on('close', () => socket.destroy());
      client.write(lines.join('\r\n') + '\r\n\r\n');
      if (pendingUpstreamData.length) client.write(pendingUpstreamData);
      if (pendingClientData.length) socket.write(pendingClientData);
      client.pipe(socket).pipe(client);
    });
    upstream.end();
  });

  server.listen(port, host, () => {
    const publicUrl = new URL(`http://${host}:${server.address().port}`);
    authority = publicUrl.host;
    publicOrigin = publicUrl.origin;
    writeFileSync(ready, JSON.stringify({ url: publicOrigin + source.pathname + source.search + source.hash }));
  });
}

function httpStatus(url, ca) {
  const address = new URL(url);
  return new Promise((resolve, reject) => {
    const probe = requestFor(address)(address, { signal: AbortSignal.timeout(2500), ca, rejectUnauthorized: true }, response => {
      response.resume();
      resolve(response.statusCode);
    });
    probe.on('error', reject);
    probe.end();
  });
}

function removeJob(label) {
  execFileSync(launchctl, ['remove', label], { stdio: ['ignore', 'ignore', 'pipe'] });
}

async function start(rawUrl, options) {
  let source;
  try {
    source = new URL(rawUrl);
  } catch {
    throw new Error('Supply the running local page as an HTTP or HTTPS URL.');
  }
  if (!['http:', 'https:'].includes(source.protocol) || !isLoopback(source.hostname) ||
      source.username || source.password) {
    throw new Error('Use an HTTP or HTTPS loopback URL without a username or password.');
  }
  const caFile = options.ca === undefined ? undefined : resolve(options.ca);
  if (caFile && source.protocol !== 'https:') throw new Error('--ca requires an HTTPS source.');
  const ca = caFile ? readFileSync(caFile) : undefined;
  const port = options.port === undefined ? 0 : Number(options.port);
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('Choose a valid LAN port.');

  const upstreamStatus = await httpStatus(source, ca).catch(error => {
    throw new Error(`Could not reach the source page: ${error.code ?? error.message}. Verify the local server and URL.`);
  });
  if (upstreamStatus >= 400 && upstreamStatus !== 401) {
    throw new Error(`The source page returned HTTP ${upstreamStatus}.`);
  }

  const { address: host, netmask } = lanInterface(options.bind);
  const folder = mkdtempSync(join(tmpdir(), 'codex-lan-preview-'));
  const qr = resolve(options.qr ?? join(folder, 'preview-qr.png'));
  const ready = join(folder, 'ready.json');
  const log = join(folder, 'preview.log');
  const config = join(folder, 'config.json');
  const label = labelPrefix + randomUUID();
  writeFileSync(config, JSON.stringify({ target: source.href, host, netmask, port, ready, caFile }));
  mkdirSync(dirname(qr), { recursive: true });

  const trustEnvironment = [];
  if (source.protocol === 'https:' && !caFile) {
    if (process.env.NODE_EXTRA_CA_CERTS) {
      trustEnvironment.push(`NODE_EXTRA_CA_CERTS=${resolve(process.env.NODE_EXTRA_CA_CERTS)}`);
    }
    if (process.env.NODE_USE_SYSTEM_CA || process.execArgv.includes('--use-system-ca')) {
      trustEnvironment.push('NODE_USE_SYSTEM_CA=1');
    }
  }
  const relay = [process.execPath, script, 'serve', config];
  const command = trustEnvironment.length ? ['/usr/bin/env', ...trustEnvironment, ...relay] : relay;
  execFileSync(launchctl, [
    'submit', '-l', label, '-o', log, '-e', log, '--', ...command,
  ], { stdio: ['ignore', 'ignore', 'pipe'] });

  try {
    let result;
    for (let attempt = 0; attempt < 30; attempt++) {
      try {
        result = JSON.parse(readFileSync(ready, 'utf8'));
        break;
      } catch (error) {
        if (error.code !== 'ENOENT' && !(error instanceof SyntaxError)) throw error;
      }
      await delay(100);
    }
    if (!result) throw new Error('The LAN listener did not start.');

    const status = await httpStatus(result.url);
    if (status >= 400 && status !== upstreamStatus) throw new Error(`The LAN URL returned HTTP ${status}.`);
    execFileSync('/usr/bin/swift', [
      '-module-cache-path', join(folder, 'swift-cache'), join(dirname(script), 'qr.swift'), result.url, qr,
    ], { stdio: ['ignore', 'pipe', 'pipe'] });
    console.log(JSON.stringify({ url: result.url, qr, job: label, httpStatus: status, log }, null, 2));
  } catch (error) {
    try { removeJob(label); } catch {}
    throw new Error(`${error.message}\nPreview log: ${log}`);
  }
}

try {
  const [, , command, ...args] = process.argv;
  if (command === 'serve' && args.length === 1) {
    runProxy(args[0]);
  } else if (command === 'stop' && args.length === 1 && args[0].startsWith(labelPrefix) &&
             /^[0-9a-f-]{36}$/.test(args[0].slice(labelPrefix.length))) {
    removeJob(args[0]);
    console.log('Stopped the LAN preview.');
  } else if (command === 'start') {
    const parsed = parseArgs({
      args, allowPositionals: true,
      options: { qr: { type: 'string' }, bind: { type: 'string' }, port: { type: 'string' }, ca: { type: 'string' } },
    });
    if (parsed.positionals.length !== 1) throw new Error('Supply exactly one local HTTP URL.');
    await start(parsed.positionals[0], parsed.values);
  } else {
    throw new Error('Usage: lan-preview.mjs start <local-url> [--qr <png>] [--bind <ip>] [--port <port>] [--ca <pem>]\n' +
      '       lan-preview.mjs stop <job>');
  }
} catch (error) {
  console.error(error.stderr?.toString().trim() || error.message);
  process.exitCode = 1;
}
