defmodule Wac.Gen.LiveViews do
  @moduledoc false

  @template_path "../../templates/live_views"

  @template_files %{
    authentication: "authentication_live.ex",
    authentication_html: "authentication_live.html.heex",
    registration: "registration_live.ex",
    registration_html: "registration_live.html.heex"
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
    target = Path.join(["lib", web_snake_case, "live", file_name])
    Mix.Generator.copy_template(source, target, assigns)

    unless String.contains?(file_name, ".html.heex") do
      Code.format_file!(target)
    end
  end
end
