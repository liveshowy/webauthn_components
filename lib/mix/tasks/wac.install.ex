defmodule Mix.Tasks.Wac.Install do
  @moduledoc """
  Generates schemas, migrations, and contexts for users with WebauthnComponents as the primary authentication mechanism.

  ## Options

  By default, contexts, schemas, tests, and web modules are generated or modified by `wac.install`. You may opt out of one or more generators with the following options:

  - `--no-contexts`: Do not generate context modules.
  - `--no-schemas`: Do not generate schema & migration modules.
  - `--no-tests`: Do not generate test modules & scripts.
  - `--no-web`: Do not generate the authentication LiveView, the session controller, or session hooks.
  - `--no-router`: Do not modify the router.

  ## Templates

  Within the [`webauthn_components`](https://github.com/liveshowy/webauthn_components) repo, the following templates are used by `wac.install` to scaffold the modules needed to support Passkeys in a LiveView application:

  #{for dir <- File.ls!("templates") |> Enum.sort(),
  file <- Path.join(["templates", dir]) |> File.ls!() |> Enum.sort() do
    "\n- `templates/#{dir}/#{file}`"
  end}
  """
  use Mix.Task
  alias Wac.Gen.Contexts
  alias Wac.Gen.Controllers
  alias Wac.Gen.Schemas
  alias Wac.Gen.LiveViews
  alias Wac.Gen.SessionHooks
  alias Wac.Gen.Migrations
  alias Wac.Gen.Router
  alias Wac.Gen.Tests
  alias Wac.Gen.Fixtures
  alias Wac.Gen.Javascript
  alias Wac.Gen.Components
  alias Wac.Gen.AppHtml

  @version Mix.Project.config()[:version]
  @shortdoc "Generates a user schema."

  @mix_task "wac.install"
  @switches [
    contexts: :boolean,
    schemas: :boolean,
    tests: :boolean,
    web: :boolean,
    router: :boolean
  ]
  @default_opts [
    contexts: true,
    schemas: true,
    tests: true,
    web: true,
    router: true
  ]

  @requirements ["app.start"]

  @impl Mix.Task
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("WebauthnComponents Schemas generator v#{@version}")
  end

  def run([version]) when version in ~w(-h --help) do
    Mix.Tasks.Help.run([@mix_task])
  end

  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.shell().error("Sorry, umbrella projects are currently unsupported.")
    end

    case OptionParser.parse(args, strict: @switches) do
      {flags, _args, []} ->
        opts = Keyword.merge(@default_opts, flags)
        dirname = File.cwd!() |> Path.basename()
        dirname_camelized = Macro.camelize(dirname)
        web_dirname = dirname <> "_web"
        web_dirname_camelized = Macro.camelize(web_dirname)

        assigns = [
          app_snake_case: dirname,
          app_pascal_case: Module.concat([dirname_camelized]),
          web_snake_case: web_dirname,
          web_pascal_case: Module.concat([web_dirname_camelized])
        ]

        if opts[:contexts] do
          Contexts.copy_templates(assigns)
        end

        if opts[:schemas] do
          Schemas.copy_templates(assigns)
          Migrations.copy_templates(assigns)
        end

        if opts[:tests] do
          Tests.copy_templates(assigns)
          Fixtures.copy_templates(assigns)
        end

        if opts[:web] do
          Components.copy_templates(assigns)
          Controllers.copy_templates(assigns)
          LiveViews.copy_templates(assigns)
          AppHtml.update_app_html(assigns)
          SessionHooks.copy_templates(assigns)
          Javascript.inject_hooks()
        end

        if opts[:router] do
          Router.update_router(assigns)
        end

        success_message =
          """

          ✅ Successfully scaffolded WebauthnComponents for #{assigns[:app_pascal_case]}

          📚 Resources

          - Repo:\thttps://github.com/liveshowy/webauthn_components
          - Hex:\thttps://hex.pm/packages/webauthn_components
          - Docs:\thttps://hexdocs.pm/webauthn_components/readme.html
          """

        IO.puts(success_message)

      {_parsed, _args, errors} ->
        invalid_opts =
          errors
          |> Enum.map_join(", ", &elem(&1, 0))

        Mix.Tasks.Help.run([@mix_task])
        Mix.shell().error("Invalid option(s): #{invalid_opts}")
    end
  end
end
