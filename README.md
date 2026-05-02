# Passeur SearXNG

MCP tool for [Passeur](https://github.com/jfim/passeur) that performs web searches via a [SearXNG](https://docs.searxng.org/) instance.

## Tools

| Tool | Description |
|------|-------------|
| `web_search` | Perform a web search and return formatted results |
| `web_search_info` | Return available categories and configured engines for the SearXNG instance |

### `web_search` parameters

- `query` (required) — search terms
- `categories` (optional) — comma-separated categories (e.g. `"general,news"`)
- `engines` (optional) — comma-separated engines to restrict the search to
- `language` (optional, default `"en"`) — language code
- `pageno` (optional, default `1`) — page number
- `time_range` (optional) — `"day"`, `"month"`, or `"year"`
- `response_format` (optional, default `"markdown"`) — `"markdown"` or `"json"`

## Configuration

| Env var | Description |
|---------|-------------|
| `SEARXNG_URL` | Base URL of the SearXNG instance (e.g. `https://searxng.example.com`) |

## Usage

Add to your MCP server project:

```elixir
# mix.exs
{:passeur_searxng, path: "../passeur_searxng"}
```

Register the tools in your MCP server:

```elixir
defmodule MyServer.MCPServer do
  use Anubis.Server,
    name: "MyServer",
    version: "0.1.0",
    capabilities: [:tools]

  component PasseurSearxng.Tools.WebSearch
  component PasseurSearxng.Tools.WebSearchInfo

  @impl true
  def init(_client_info, frame), do: {:ok, frame}
end
```

## License

MIT
