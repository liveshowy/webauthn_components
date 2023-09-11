defmodule Mix.Tasks.Wac.Install do
  @moduledoc """
  Generates schemas, migrations, and contexts for users with WebauthnComponents as the primary authentication mechanism.
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

  @version Mix.Project.config()[:version]
  @shortdoc "Generates a user schema."

  @mix_task "wac.install"
  @switches []

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
      {_parsed, _args, []} ->
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

        Schemas.copy_templates(assigns)
        Migrations.copy_templates(assigns)
        Contexts.copy_templates(assigns)
        Tests.copy_templates(assigns)
        Fixtures.copy_templates(assigns)
        Controllers.copy_templates(assigns)
        SessionHooks.copy_templates(assigns)
        LiveViews.copy_templates(assigns)
        Router.update_router(assigns)

      {_parsed, _args, errors} ->
        invalid_opts =
          errors
          |> Enum.map_join(", ", &elem(&1, 0))

        Mix.Tasks.Help.run([@mix_task])
        Mix.shell().error("Invalid option(s): #{invalid_opts}")
    end
  end
end
