# Xcode MCP Setup

## Activate MCP

Upgrade Xcode to v26.3+ (from the App Store or [official Apple downloads page](https://developer.apple.com/download/all/)). It has Xcode: `Settings → Intelligence → Model Context Protocol → “Allow External Agents to Use Xcode Tools”`.

OpenCode (or any MCP client) starts `mcpbridge` when it needs the tools and talks to it over stdin/stdout. Xcode itself must be running with the project open, and the Intelligence → Model Context Protocol setting must be enabled.

---

## How to add Xcode to your global `opencode.jsonc`

Because OpenCode runs **inside a Linux container**, a plain `"command": ["xcrun", "mcpbridge"]` will fail — `xcrun` does not exist in the container.

You have two practical options.

### Option A – SSH tunnel (simplest if you already have SSH to the host)

Add this next to your existing `intellij` entry:

```jsonc
"xcode": {
  "type": "local",
  "command": [
    "ssh",
    "-T",
    "-o", "StrictHostKeyChecking=accept-new",
    "-o", "BatchMode=yes",
    "YOUR_MAC_USER@host.docker.internal",
    "xcrun", "mcpbridge"
  ],
  "disabled": false,
  "timeout": 60000
}
```

Replace `YOUR_MAC_USER` with your macOS username.  
Make sure key-based SSH works from the container without a password prompt.

### Option B – HTTP proxy / broker on the host (recommended for daily use)

On the **Mac host** install and run a persistent proxy, e.g.:

- [XcodeMCPKit](https://github.com/lynnswap/XcodeMCPKit) → `http://localhost:8765/mcp`
- or [XcodeMCPBroker](https://github.com/grahammckee/XcodeMCPBroker) → `http://127.0.0.1:7341/mcp`

**NOTE**: see installation details below.

Then in the container’s `opencode.jsonc`:

```jsonc
"xcode": {
  "type": "remote",
  "url": "http://host.docker.internal:8765/mcp",   // or :7341/mcp
  "disabled": false,
  "oauth": false
}
```

(Port-forward / allow the host port if needed.)

After changing the config run:

```bash
opencode mcp list
```

You should see `xcode` connected and a list of tools (≈21 tools on Xcode 26.6).

---

## What to put in `AGENTS.md` and skills

Xcode’s MCP does **not** ship official skills the way some other servers do. A short, explicit section in `AGENTS.md` is the most effective way to guide the agent.

Add something like this to `./.agents/AGENTS.md` (or the path you already list under `instructions`):

```markdown
## Xcode / iOS builds

- The project is opened in Xcode on the host Mac.
- Use the **xcode** MCP server for builds, tests and diagnostics.
- Preferred workflow:
  1. Call `XcodeListWindows` (or equivalent) to obtain the current `tabIdentifier`.
  2. Use `BuildProject` with that `tabIdentifier`.
  3. On failure, read the returned errors **and** call the diagnostics / Issue Navigator tool.
  4. After fixing code, rebuild and re-check diagnostics.
- Always report OK/KO plus the exact list of errors (file, line, message).
- Prefer the Xcode MCP tools over shell `xcodebuild` when the project is open in Xcode.
- Do not assume a scheme or destination; discover them via the MCP tools when needed.
```

You do **not** need extra skills just to make the MCP tools appear.  
If you later add **XcodeBuildMCP** (the headless `xcodebuild`/`simctl` server) you can run its `init` command to get companion skills, but that is optional and complementary, not required for the official Xcode MCP.

---

## Practical recommendation (Xcode 26.6+ and container) SUMMARY

| Step | Action |
|------|--------|
| 1 | Xcode 26.6 open with the project, Intelligence → Model Context Protocol enabled (you already did this). |
| 2 | Choose a bridge: SSH tunnel **or** HTTP proxy (XcodeMCPKit / XcodeMCPBroker) on the Mac. |
| 3 | Add the corresponding `xcode` entry to global `opencode.jsonc` (see above). |
| 4 | Put the short “Xcode / iOS builds” section into `AGENTS.md`. |
| 5 | Restart OpenCode / reload MCP, then `opencode mcp list` to confirm. |
| 6 | Test with a prompt such as: “Build the project with the Xcode MCP and report success or the full list of errors.” |

Xcode 26.6 exposes roughly 21 tools (build, diagnostics, windows, current file, etc.). The much richer surface (~50+ tools, better simulator/device interaction, headless mode) arrives in Xcode 27.

If you tell me whether you prefer the SSH route or an HTTP proxy, I can give the exact one-liner install + config for that choice.

# Persistent proxy installation

## XcodeMCPKit

Apple Silicon only. Doesn't fit for my old MacBook with Intel CPU :(

## XcodeMCPBroker

```bash
git clone https://github.com/grahammckee/XcodeMCPBroker.git
cd XcodeMCPBroker
npm install
npm test
# Important: 
#   set broker host to 0.0.0.0. Without it broker will listen only 
#   on localhost (127.0.0.1), and refuse access from container to host,
#   which has host value equal `host.docker.internal`
XCODE_MCP_BROKER_HOST=0.0.0.0 npm run service:install
```

### Confirm the running process (on the Mac host)

```bash
# What is listening, and with which env?
lsof -nP -iTCP:7341 -sTCP:LISTEN
# You want: One listener on *:7341 or 0.0.0.0:7341 (not only 127.0.0.1:7341)

launchctl print gui/$(id -u)/com.gmicc.opencode-xcode-mcp-broker | head -80
# You want: Env containing XCODE_MCP_BROKER_HOST=0.0.0.0

# Log should show: listening on http://0.0.0.0:7341/mcp
tail -30 ~/Library/Logs/xcode-mcp-broker.log
# You want: Log should show: listening on http://0.0.0.0:7341/mcp
```

### Reproduce OpenCode’s call from the container

```bash
curl -sv -X POST \
  -H "Host: host.docker.internal:7341" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
  http://host.docker.internal:7341/mcp
```
Output:
```text
*   Trying 192.168.65.254:7341...
* Connected to host.docker.internal (192.168.65.254) port 7341 (#0)
> POST /mcp HTTP/1.1
> Host: host.docker.internal:7341
> User-Agent: curl/7.88.1
> Content-Type: application/json
> Accept: application/json, text/event-stream
> Content-Length: 151
> 
< HTTP/1.1 200 OK
< X-Powered-By: Express
< cache-control: no-cache, no-transform
< connection: keep-alive
< content-type: text/event-stream
< mcp-session-id: 970e2f5b-879f-4787-ab44-70308055f294
< x-accel-buffering: no
< content-length: 194
< Date: Mon, 09 Nov 2026 14:06:26 GMT
< 
event: message
data: {"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{"listChanged":true}},"serverInfo":{"name":"xcode-mcp-broker","version":"1.1.4"}},"jsonrpc":"2.0","id":1}

* Connection #0 to host host.docker.internal left intact
```  