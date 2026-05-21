defmodule PasseurSearxng.HTTP do
  @moduledoc false

  @request_timeout_ms 15_000
  @user_agent "PasseurSearxng/0.1"

  @spec get_json(String.t(), [{String.t(), String.t()}]) ::
          {:ok, map() | list()} | {:error, String.t()}
  def get_json(url, query_params) do
    full_url = build_url(url, query_params)

    request =
      Finch.build(:get, full_url, [{"user-agent", @user_agent}, {"accept", "application/json"}])

    case Finch.request(request, PasseurSearxng.Finch, receive_timeout: @request_timeout_ms) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, "SearXNG returned invalid JSON"}
        end

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, "SearXNG returned HTTP #{status}#{body_snippet(body)}"}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, "Request timed out"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  rescue
    e -> {:error, "Request raised #{inspect(e.__struct__)}: #{Exception.message(e)}"}
  end

  defp body_snippet(body) when is_binary(body) do
    trimmed = body |> String.trim() |> String.slice(0, 200)
    if trimmed == "", do: "", else: ": #{trimmed}"
  end

  defp build_url(base, []), do: base

  defp build_url(base, params) do
    base <> "?" <> URI.encode_query(params)
  end
end
