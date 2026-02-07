defmodule TestApp.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Create ETS table for sessions (allows storing tokens without cookie overflow)
    :ets.new(:test_app_sessions, [:named_table, :public, read_concurrency: true])

    children = [
      TestAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TestAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
