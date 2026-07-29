defmodule WebauthnComponents.MixProject do
  use Mix.Project

  # Don't forget to change the version in `package.json`
  @name "WebauthnComponents"
  @source_url "https://github.com/liveshowy/webauthn_components"
  @version "0.8.0"

  def project do
    [
      app: :webauthn_components,
      deps: deps(),
      description: description(),
      docs: docs(),
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false, optional: true},
      {:ecto, "~> 3.10"},
      {:ex_doc, "~> 0.34", only: [:dev], runtime: false, optional: true},
      {:floki, "~> 0.36", only: [:test], optional: true},
      {:jason, "~> 1.0", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test, optional: true},
      {:live_isolated_component, "~> 0.10", only: [:test], optional: true},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 1.2", override: true},
      {:phoenix, "~> 1.6"},
      {:sourceror, "~> 1.12"},
      {:wax_, "~> 0.7"}
    ]
  end

  defp docs do
    [
      main: "readme",
      name: @name,
      formatters: ["html"],
      canonical: "https://hexdocs.pm/webauthn_components",
      nest_modules_by_prefix: [
        WebauthnComponents
      ],
      groups_for_modules: [
        Components: ~r/Component$/,
        Support: [
          WebauthnComponents.CoseKey,
          WebauthnComponents.WebauthnUser
        ]
      ],
      source_url: @source_url,
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: ["README.md", "webauthn_flows.md"]
    ]
  end

  defp description do
    "Passkey authentication for Phoenix LiveView applications."
  end

  defp package do
    [
      files: ~w(lib priv templates mix.exs README.md LICENSE package.json),
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
