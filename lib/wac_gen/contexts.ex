defmodule Wac.Gen.Contexts do
  @moduledoc false

  @template_files %{
    users: "users.ex",
    user_keys: "user_keys.ex",
    user_tokens: "user_tokens.ex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand("../../templates/contexts", __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["lib", app_snake_case, file_name])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
