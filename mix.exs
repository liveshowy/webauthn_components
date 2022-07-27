defmodule WebauthnLiveComponent.MixProject do
  use Mix.Project

  @source_url "https://github.com/liveshowy/webauthn_live_component"
  @version "0.1.0"

  def project do
    [
      app: :webauthn_live_component,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version,
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
      {:phoenix, "~> 1.6"},
      {:phoenix_live_view, "~> 0.17"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:phoenix_ecto, "~> 4.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
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
    WebAuthnLiveComponent allows Phoenix developers to quickly add passwordless authentication to LiveView applications.
    """
  end

  defp package do
    [
      maintainers: ["Owen Bickford"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
