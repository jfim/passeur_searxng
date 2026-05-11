defmodule PasseurSearxng.MixProject do
  use Mix.Project

  def project do
    [
      app: :passeur_searxng,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "MCP tool for performing web searches via a SearXNG instance",
      package: package(),
      source_url: "https://github.com/jfim/passeur_searxng"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PasseurSearxng.Application, []}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jfim/passeur_searxng"}
    ]
  end

  defp deps do
    [
      {:anubis_mcp, git: "https://github.com/jfim/anubis-mcp.git", branch: "non-upstreamed-fixes", override: true},
      {:finch, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end
end
