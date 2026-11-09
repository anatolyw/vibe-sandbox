# IntelliJ CE MCP setup

1. In IntelliJ IDEA Community Edition (2025.2+): **Settings → Tools → MCP Server → enable Enable MCP Server**.
1. Click **Copy SSE Config** or **Copy HTTP Stream Config**. Note the port (usually starts at `64342`).
1. **NOTE**: Don't put that port into `.env`. Instead, put a proxy port `64343` (see, [./start-intellij-mcp-proxy.sh](./start-intellij-mcp-proxy.sh) ) as `IDEA_MCP_PORT`.
1. (Recommended for Docker) In **Settings → Build, Execution, Deployment → Debugger** enable **Can accept external connections** so the MCP server is reachable from the container via `host.docker.internal`. **NOTE:** cannot find this settings in the recent IntelliJ versions!
1. **NOTE**: The official IntelliJ MCP server binds only to 127.0.0.1, not to all interfaces. From a container, host.docker.internal reaches the host, but the MCP port is not listening there, so you get a refused / forbidden response. We set Host-side reverse proxy (recommended by JetBrains) with `mitmproxy`:

```bash
# install once
brew install mitmproxy
# run IntelliJ and open related Project before start proxy
./start-intellij-mcp-proxy.sh
```

Inside the container the agent can then use:

```text
$IDEA_MCP_URL            → http://host.docker.internal:64342/sse
$IDEA_MCP_STREAM_URL     → http://host.docker.internal:64342/stream
```

With the optional `IJ_MCP_SERVER_PROJECT_PATH` header if your client needs it.