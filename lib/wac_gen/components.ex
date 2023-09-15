defmodule Wac.Gen.Components do
  @moduledoc false

  @template_path "../../templates/components"

  @template_files %{
    navigation_components: "navigation_components.ex",
    navbar: "navigation/navbar.html.heex",
    nav_link: "navigation/nav_link.html.heex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["lib", web_snake_case, "components", file_name])
    Mix.Generator.copy_template(source, target, assigns)

    unless String.contains?(file_name, ".heex") do
      Code.format_file!(target)
    end
  end
end