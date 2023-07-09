defmodule Mix.Tasks.Wac.Gen.Schemas do
  @moduledoc """
  Generates schemas, migrations, and contexts for users with WebauthnComponents as the primary authentication mechanism.
  """
  @shortdoc "Generates a user schema."

  use Mix.Task
  alias Wac.Gen.Builder

  @version Mix.Project.config()[:version]

  @switches []

  @impl Mix.Task
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("WebauthnComponents Schemas generator v#{@version}")
  end

  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.shell().error("Sorry, umbrella projects are currently unsupported.")
    end

    case OptionParser.parse(args, strict: @switches) do
      {_parsed, _args, []} ->
        dirname = File.cwd!() |> Path.basename()

        assigns = [
          app_snake_case: dirname,
          app_pascal_case: Module.concat([Macro.camelize(dirname)])
        ]

        Builder.copy_templates(assigns)

      {_parsed, _args, errors} ->
        invalid_opts =
          errors
          |> Enum.map_join(", ", &elem(&1, 0))

        Mix.Tasks.Help.run(["wac.gen.schemas"])
        Mix.shell().error("Invalid option(s): #{invalid_opts}")
    end
  end
end
