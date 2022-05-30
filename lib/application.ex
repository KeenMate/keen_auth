defmodule KeenAuth.Application do
  use Application

  def start (_opts) do
    children =
      [
        KeenAuth.TokenStorage,
        workers_pool()
      ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp workers_pool() do
    :poolboy.child_spec(
      :workers_pool,
      [
        worker_module: KeenAuth.KeenWorker,
        size: 2,
        max_overflow: 0
      ],
      []
    )
  end
end
