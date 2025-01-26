defmodule Clr.MixProject do
  use Mix.Project

  def project do
    [
      app: :clr,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:pegasus, "~> 0.2"},
      {:protoss, "~> 1.0"},
      {:zig_parser, "~> 0.2"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
