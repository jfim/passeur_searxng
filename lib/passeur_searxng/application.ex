defmodule PasseurSearxng.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: PasseurSearxng.Finch}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PasseurSearxng.Supervisor)
  end
end
