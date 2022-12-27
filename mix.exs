defmodule WebAuthnLiveComponent.MixProject do
  use Mix.Project

  # Don't forget to change the version in `package.json`
  @source_url "https://github.com/liveshowy/webauthn_live_component"
  @version "0.2.0"

  def project do
    [
      app: :webauthn_live_component,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "WebAuthnLiveComponent",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: [:dev], runtime: false},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.17"},
      {:uuid, "~> 1.1"},
      {:wax_, "~> 0.4"}
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "WebAuthn LiveComponent",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/webauthn_live_component",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp description do
    """
    Passwordless authentication for LiveView applications.
    """
  end

  defp package do
    [
      files: ~w(lib priv mix.exs README.md LICENSE package.json),
      licenses: ["MIT"],
      links: %{
        Github: @source_url
      },
      maintainers: ["Owen Bickford"]
    ]
  end
end
