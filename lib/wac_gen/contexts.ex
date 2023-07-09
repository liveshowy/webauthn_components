defmodule Wac.Gen.Contexts do
  @moduledoc """
  Functions for generating a User schema and migration.
  """

  @template_paths %{
    users: "users.ex",
    user_keys: "user_keys.ex",
    user_tokens: "user_tokens.ex"
  }

  @templates Map.keys(@template_paths)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_path = @template_paths[template]
    template_dir = Path.expand("../../templates", __DIR__)
    source = Path.join([template_dir, file_path])
    target = Path.join(["lib", app_snake_case, file_path])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
