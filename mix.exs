defmodule Mandarin.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :mandarin,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      # {:forage, "~> 0.2"},
      {:forage, path: "../forage"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:inflex, "~> 2.0.0"},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description() do
    "Admin interface generator"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "mandarin",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/mandarin"}
    ]
  end
end
