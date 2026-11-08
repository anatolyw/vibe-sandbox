# VSCode MCP setup

**NOTE**: VSCode MCP Server by Semantic Workbench Team looks obsolete. The below reference stays here as example!

1. Install the extension: **VSCode MCP Server** by Semantic Workbench Team (`SemanticWorkbenchTeam.mcp-server-vscode`).
2. It starts automatically (default port `6010`).
3. To change the port:
  - Command Palette → `Set MCP Server Port`, or
  - Settings → search `mcpServer.port`.
4. Put the actual port into `.env` as `VSCODE_MCP_PORT`.
5. No extra “accept external connections” toggle is required (unlike IntelliJ’s debugger setting), but the server must be running while the container is up.

Inside the container the agent can then use:

```text
$VSCODE_MCP_URL          → http://host.docker.internal:6010/sse
```