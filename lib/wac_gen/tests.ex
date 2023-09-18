defmodule Wac.Gen.Tests do
  @moduledoc false

  @template_path "../../templates/tests"

  @template_files %{
    identity: "identity_test.exs",
    authentication_live: "authentication_live_test.exs"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(:identity = template, assigns) when is_list(assigns) do
    app_snake_case = Keyword.fetch!(assigns, :app_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["test", app_snake_case, file_name])
    Mix.Generator.copy_template(source, target, assigns)
    Code.format_file!(target)
  end

  def copy_template(:authentication_live = template, assigns) when is_list(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["test", web_snake_case, "live", file_name])
    Mix.Generator.copy_template(source, target, assigns)
    Code.format_file!(target)
  end
end
