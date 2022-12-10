defmodule Sample.MixProject do
  use Mix.Project

  def project do
    [
      app: :sample,
      version: "0.1.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Sample.App, []},
      # ash_app to ensure node is up on app start
      extra_applications: [
        :logger,
        :ash_app,
        :ash_term
      ]
    ]
  end

  defp deps do
    [
      {:ash_react, path: ".."},
      {:ash_tui, path: "../../ash_tui"},
      {:ash_app, path: "../../ash_app"},
      {:ash_tool, path: "../../ash_tool"},
      {:ash_term, path: "../../ash_term"}
    ]
  end
end
