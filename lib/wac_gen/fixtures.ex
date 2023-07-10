defmodule Wac.Gen.Fixtures do
  @moduledoc """
  Functions for generating a User schema and migration.
  """

  @template_files %{
    users: "user_fixtures.ex"
    # user_keys: "user_keys_test.exs",
    # user_tokens: "user_tokens_test.exs"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    file_name = @template_files[template]
    template_dir = Path.expand("../../templates/fixtures", __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["test", "support", file_name])
    Mix.Generator.copy_template(source, target, assigns)
  end
end
