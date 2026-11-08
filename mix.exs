defmodule IDUtils.MixProject do
  use Mix.Project

  @version "0.0.1"
  @description "Utilities for persistent identifiers used in scholarly communication"
  @source_url "https://github.com/moefuerst/id_utils"

  def project do
    [
      app: :id_utils,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs(),
      source_url: @source_url,
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test, check: :test, "test.ci": :test, dialyzer: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Development and Testing
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:oeditus_credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:muex, "~> 0.8", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "dialyzer --quiet-with-result",
        "test --warnings-as-errors"
      ],
      check: [
        "deps.unlock --check-unused",
        "format --check-formatted",
        "credo --strict"
      ],
      "deps.audit": [
        "hex.audit",
        "deps.audit"
      ],
      "test.ci": [
        "test --warnings-as-errors"
      ]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_core_path: "_build/#{Mix.env()}/plt",
      plt_file: {:no_warn, "_build/#{Mix.env()}/plt/dialyzer.plt"},
      plt_add_apps: [:ex_unit]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      name: :id_utils,
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["BSD-3-Clause"],
      maintainers: ["Moritz F. Fürst"],
      source_url: @source_url,
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Source Code" => @source_url
      }
    ]
  end
end
