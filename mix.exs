defmodule CredoNaming.MixProject do
  use Mix.Project

  @source_url "https://github.com/mirego/credo_naming"
  @version "1.0.0"

  def project do
    [
      version: @version,
      app: :credo_naming,
      name: "CredoNaming",
      description: "A suite of checks to enforce naming best practices in an Elixir project.",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package(),
      elixir: "~> 1.8",
      start_permanent: false,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    %{
      maintainers: ["Rémi Prévost"],
      licenses: ["BSD-3"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    }
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "CHANGELOG.md",
        "README.md"
      ]
    ]
  end
end
