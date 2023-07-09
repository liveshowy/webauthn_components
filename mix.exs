defmodule WebauthnComponents.MixProject do
  use Mix.Project

  # Don't forget to change the version in `package.json`
  @source_url "https://github.com/liveshowy/webauthn_components"
  @version "0.5.0"

  def project do
    [
      app: :webauthn_components,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "WebauthnComponents",
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30", only: [:dev], runtime: false},
      {:ecto, "~> 3.10"},
      {:floki, "~> 0.34.2", only: [:test]},
      {:jason, "~> 1.0"},
      {:live_isolated_component, "~> 0.6.4", only: [:test]},
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.17"},
      {:uuid, "~> 1.1"},
      {:ecto_ulid, "~> 0.3"},
      {:wax_, "~> 0.6.1"}
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "WebauthnComponents",
      formatters: ["html"],
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/webauthn_components",
      nest_modules_by_prefix: [WebauthnComponents],
      source_url: @source_url,
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: ["README.md", "USAGE.md"]
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

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@8.13.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
