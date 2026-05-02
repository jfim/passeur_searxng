defmodule PasseurSearxng.Config do
  @moduledoc "Runtime configuration read from environment variables."

  @url_env "SEARXNG_URL"

  @spec searxng_url() :: String.t() | nil
  def searxng_url, do: System.get_env(@url_env)
end
