defmodule UeberauthTrello.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/emilsoman/ueberauth_trello"

  def project do
    [app: :ueberauth_trello,
     version: @version,
     name: "Ueberauth Trello Strategy",
     package: package(),
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: @url,
     homepage_url: @url,
     description: description(),
     deps: deps(),
     docs: docs()]
  end

  def application do
    [applications: [:logger, :httpoison, :oauther, :ueberauth]]
  end

  defp deps do
    [
     {:httpoison, "~> 1.0"},
     {:oauther, "~> 1.1"},
     {:ueberauth, "~> 0.6"},

     # dev/test dependencies
     {:earmark, ">= 0.0.0", only: :dev},
     {:ex_doc, "~> 0.18", only: :dev},
     {:credo, "~> 0.8", only: [:dev, :test]}
    ]
  end

  defp docs do
    [extras: docs_extras(), main: "extra-readme"]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp description do
    "An Uberauth strategy for Trello authentication."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Emil Soman"],
     licenses: ["MIT"],
     links: %{"GitHub": @url}]
  end
end
