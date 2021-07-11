defmodule Stocks.MixProject do
  use Mix.Project

  def project do
    [
      app: :stocks,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        stocks: [
          steps: [:assemble, &Bakeware.assemble/1],
          bakeware: [
            compression_level: 19,
            start_command: "start"
          ]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Stocks, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "1.2.2"},
      {:httpoison, "1.8.0"},
      {:table_rex, "~> 3.1"},
      {:number, "1.0.3"},
      {:bakeware, "0.2.0"}
    ]
  end
end
