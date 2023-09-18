defmodule Wac.Gen.Schemas do
  @moduledoc false

  @template_path "../../templates/schemas"

  @template_files %{
    user: "user.ex",
    user_key: "user_key.ex",
    user_token: "user_token.ex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_name = @template_files[template]
    dir_name = "identity"
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["lib", app_snake_case, dir_name, file_name])
    Mix.Generator.copy_template(source, target, assigns)
    Code.format_file!(target)
  end
end
