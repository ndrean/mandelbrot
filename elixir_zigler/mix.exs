defmodule Zigit.MixProject do
  use Mix.Project

  def project do
    [
      app: :zigit,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Zigit.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:zigler, "~> 0.13.3"},
      {:vix, "~> 0.31"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
