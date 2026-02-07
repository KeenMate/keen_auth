defmodule TestApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TestApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},

      # KeenAuth as path dependency
      {:keen_auth, path: ".."}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
