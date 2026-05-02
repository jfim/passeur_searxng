defmodule PasseurSearxng.Tools.WebSearchInfo do
  @moduledoc "Return available SearXNG categories and configured engines"

  use Anubis.Server.Component, type: :tool
  require Logger

  @overall_timeout_ms 30_000

  schema do
  end

  @impl true
  def execute(_params, frame) do
    Logger.info("SearXNG info request")

    task = Task.async(fn -> do_info() end)

    result =
      case Task.yield(task, @overall_timeout_ms) || Task.shutdown(task, :brutal_kill) do
        {:ok, {:ok, text}} -> text
        {:ok, {:error, reason}} -> "Error: #{reason}"
        nil -> "Error: Operation timed out after #{@overall_timeout_ms}ms"
      end

    {:reply, Anubis.Server.Response.tool() |> Anubis.Server.Response.text(result), frame}
  end

  defp do_info do
    with {:ok, base} <- searxng_base(),
         {:ok, decoded} <- PasseurSearxng.HTTP.get_json(base <> "/config", []) do
      {:ok, format_info(decoded)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp searxng_base do
    case PasseurSearxng.Config.searxng_url() do
      nil -> {:error, "SEARXNG_URL environment variable is not set"}
      url -> {:ok, String.trim_trailing(url, "/")}
    end
  end

  defp format_info(decoded) do
    categories =
      decoded
      |> Map.get("categories", [])
      |> Enum.sort()

    engines =
      decoded
      |> Map.get("engines", [])
      |> Enum.filter(fn e -> not Map.get(e, "disabled", false) end)
      |> Enum.map(fn e -> Map.get(e, "name", "(unknown)") end)
      |> Enum.sort()

    """
    # SearXNG Configuration

    ## Categories (#{length(categories)})

    #{format_list(categories)}

    ## Enabled Engines (#{length(engines)})

    #{format_list(engines)}
    """
  end

  defp format_list([]), do: "_(none)_"
  defp format_list(items), do: items |> Enum.map(&"- #{&1}") |> Enum.join("\n")
end
