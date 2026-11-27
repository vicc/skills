# Share Localhost

Open a web app running on your Mac from a phone or tablet on the same network. Codex gives you a link and a QR code that preserve the page you were viewing.

## Install

```bash
npx skills@latest add vicc/skills --agent codex --skill vicc-share-localhost
```

## Try it

> I have a preview running at localhost:5173/dashboard. Use $vicc-share-localhost so I can try that page on my phone.

Keep the source app running. If it only listens on localhost, the skill uses Node.js 18.3 or later, launchd, and Swift to start a relay and gives you the command to stop it. People who can reach the relay can access other routes on that app, too.

[Skill instructions](SKILL.md)
