defmodule Wac.Gen.Tests do
  @moduledoc false

  @template_files %{
    users: "users_test.exs"
    # user_keys: "user_keys_test.exs",
    # user_tokens: "user_tokens_test.exs"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand("../../templates/tests", __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["test", app_snake_case, file_name])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
