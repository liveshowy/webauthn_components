defmodule Mix.Tasks.Wac.Gen.Schemas do
  @moduledoc """
  Generates schemas, migrations, and contexts for users with WebauthnComponents as the primary authentication mechanism.
  """
  @shortdoc "Generates a user schema."

  use Mix.Task
  alias Wac.Gen.Builder

  @version Mix.Project.config()[:version]

  @mix_task "wac.gen.schemas"
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

        assigns = [
          app_snake_case: dirname,
          app_pascal_case: Module.concat([dirname_camelized])
        ]

        Builder.copy_templates(assigns)

      {_parsed, _args, errors} ->
        invalid_opts =
          errors
          |> Enum.map_join(", ", &elem(&1, 0))

        Mix.Tasks.Help.run([@mix_task])
        Mix.shell().error("Invalid option(s): #{invalid_opts}")
    end
  end
end
