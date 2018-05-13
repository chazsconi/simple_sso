defmodule SimpleSSO.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_sso,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "SimpleSSO",
      source_url: "https://github.com/chazsconi/simple_sso",
      docs: docs()
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
      {:oauth2, "~> 0.9"},
      {:phoenix, "~> 1.2"},
      {:simple_auth, "~> 1.6.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Adds Single Sign On to a Phoenix app
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :simple_sso,
      maintainers: ["Charles Bernasconi"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/chazsconi/simple_sso"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
