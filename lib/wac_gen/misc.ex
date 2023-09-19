defmodule Wac.Gen.Misc do
  @moduledoc false
  alias Sourceror.Zipper

  @template_path "../../templates/misc"

  @template_files %{
    user_token_cleaner: "user_token_cleaner.ex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["lib", app_snake_case, file_name])
    Mix.Generator.copy_template(source, target, assigns)
    Code.format_file!(target)

    inject_application_child(assigns)
  end

  def inject_application_child(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    application_file_path = Path.join(["lib", app_snake_case, "application.ex"])

    updated_contents =
      application_file_path
      |> File.read!()
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      |> insert_cleaner_child(assigns)
      |> Zipper.root()
      |> Sourceror.to_string()

    File.write!(application_file_path, updated_contents)
  end

  defp insert_cleaner_child(%Zipper{} = zipper, assigns) do
    zipper
    |> Zipper.find(&find_repo_child/1)
    |> Zipper.insert_right(token_cleaner_child(assigns))
  end

  defp find_repo_child({:__aliases__, _meta, [_, :Repo]}), do: true
  defp find_repo_child(_), do: false

  defp token_cleaner_child(assigns) do
    app_web_case = Keyword.fetch!(assigns, :app_pascal_case)

    """
    # Start the UserTokenCleaner
    {#{inspect(app_web_case)}.UserTokenCleaner, interval_minutes: 10}
    """
    |> Sourceror.parse_string!()
  end
end
