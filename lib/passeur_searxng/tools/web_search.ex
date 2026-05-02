defmodule PasseurSearxng.Tools.WebSearch do
  @moduledoc "Perform a web search via a SearXNG instance"

  use Anubis.Server.Component, type: :tool
  require Logger

  @overall_timeout_ms 30_000
  @max_results_markdown 10

  schema do
    field(:query, {:required, :string}, description: "Search query")
    field(:categories, :string, description: "Comma-separated categories (e.g. \"general,news\")")
    field(:engines, :string, description: "Comma-separated engines to restrict the search to")
    field(:language, :string, description: "Language code (default \"en\")")
    field(:pageno, :integer, description: "Page number, starting at 1 (default 1)")
    field(:time_range, :string, description: "Time filter: \"day\", \"month\", or \"year\"")
    field(:response_format, :string, description: "\"markdown\" (default) or \"json\"")
  end

  @impl true
  def execute(%{query: query} = params, frame) do
    Logger.info("SearXNG search: #{query}")

    task = Task.async(fn -> do_search(query, params) end)

    response =
      case Task.yield(task, @overall_timeout_ms) || Task.shutdown(task, :brutal_kill) do
        {:ok, {:ok, text}} ->
          Anubis.Server.Response.tool() |> Anubis.Server.Response.text(text)

        {:ok, {:error, reason}} ->
          Logger.warning("SearXNG search failed: #{reason}")
          Anubis.Server.Response.tool() |> Anubis.Server.Response.error(reason)

        {:exit, reason} ->
          msg = "SearXNG search crashed: #{inspect(reason)}"
          Logger.error(msg)
          Anubis.Server.Response.tool() |> Anubis.Server.Response.error(msg)

        nil ->
          msg = "Operation timed out after #{@overall_timeout_ms}ms"
          Logger.warning(msg)
          Anubis.Server.Response.tool() |> Anubis.Server.Response.error(msg)
      end

    {:reply, response, frame}
  end

  defp do_search(query, params) do
    with {:ok, base} <- searxng_base(),
         qp = build_query_params(query, params),
         {:ok, decoded} <- PasseurSearxng.HTTP.get_json(base <> "/search", qp) do
      {:ok, format_results(decoded, query, Map.get(params, :response_format, "markdown"))}
    end
  rescue
    e ->
      {:error, "#{inspect(e.__struct__)}: #{Exception.message(e)}"}
  end

  defp searxng_base do
    case PasseurSearxng.Config.searxng_url() do
      nil -> {:error, "SEARXNG_URL environment variable is not set"}
      url -> {:ok, String.trim_trailing(url, "/")}
    end
  end

  defp build_query_params(query, params) do
    [
      {"q", query},
      {"format", "json"},
      {"pageno", to_string(Map.get(params, :pageno, 1))},
      {"language", Map.get(params, :language, "en")}
    ]
    |> add_optional("categories", Map.get(params, :categories))
    |> add_optional("engines", Map.get(params, :engines))
    |> add_optional("time_range", Map.get(params, :time_range))
  end

  defp add_optional(list, _key, nil), do: list
  defp add_optional(list, _key, ""), do: list
  defp add_optional(list, key, value), do: list ++ [{key, value}]

  defp format_results(decoded, _query, "json"), do: Jason.encode!(decoded, pretty: true)

  defp format_results(decoded, query, _markdown) do
    results = Map.get(decoded, "results", []) |> Enum.take(@max_results_markdown)

    header = "# Search Results for: #{query}\n"

    body =
      case results do
        [] ->
          "\n_No results._\n"

        list ->
          list
          |> Enum.map(&format_result/1)
          |> Enum.join("\n")
      end

    header <> "\n" <> body
  end

  defp format_result(%{} = r) do
    title = Map.get(r, "title", "(no title)")
    url = Map.get(r, "url", "")
    content = Map.get(r, "content", "")

    "### [#{title}](#{url})\n\n#{content}\n"
  end
end
