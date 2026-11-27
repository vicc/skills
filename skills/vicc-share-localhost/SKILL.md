---
name: vicc-share-localhost
description: Share a localhost HTTP or HTTPS web app from macOS with another device on the same Wi-Fi or wired network using private IPv4. Verify the LAN link, show a scannable QR code, and keep the preview running after the turn.
---

# Share Localhost

Use this skill for any browser-based app listening on a loopback address on this Mac. The bundled helper uses Node.js 18.3 or later, macOS launchd, and the Swift toolchain. Run the commands below from this skill’s directory.

1. Identify the requested app and its running loopback URL from the user, the active browser tab, or the project's preview output. Use its actual port and preserve its path, query and fragment. If it is down, use the project's established preview command when the request authorizes starting it. Test the loopback page before sharing.
2. Anyone who can reach the preview on the subnet can request other routes on the same application origin. Choose a source suitable for the people on that network. Use the requested preview instance. When a development app has a separate preview-only instance, share that instance if it matches the request.
3. If the app is already reachable at the intended LAN address, verify that link and generate the QR with `swift scripts/qr.swift URL /absolute/path/to/preview-qr.png`. Otherwise run the bundled helper from the skill directory.

   ```bash
   node scripts/lan-preview.mjs start 'http://localhost:5173/dashboard' --qr /absolute/path/to/preview-qr.png
   ```

   Choose a writable artifact path for the PNG. The helper selects the Mac's private LAN interface, starts a launchd job, verifies the LAN URL, and generates the PNG. Use `--bind <assigned-private-ip>` when several local interfaces are plausible and `--port <port>` when the user wants a particular LAN port. Run it with the local permissions needed for a listener and a user launchd job.
4. Show the QR inline with the alt text “Scan to open the shared preview” and an absolute image path and include the full clickable LAN URL. If the helper started a job, include its exact stop command. The helper verifies the address from this Mac. Describe a separate device as tested only if it was actually used.

The launchd job persists after the turn, while the source server still needs to be running. To stop a preview, run `node scripts/lan-preview.mjs stop <job>` with the job name returned by the helper. This leaves the source app running.

If the launch fails, read the reported log path. For a phone that cannot connect, verify the source and LAN address again, then check that both devices are on the same network and that the network permits device-to-device connections. The proxy accepts HTTP and HTTPS sources and serves the LAN link over HTTP. For a local HTTPS source signed by a development CA, pass its PEM certificate with `--ca <path>`. If the browser itself needs HTTPS, use the project's existing LAN HTTPS setup and generate the QR for that address.
