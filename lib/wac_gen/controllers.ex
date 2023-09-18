defmodule Wac.Gen.Controllers do
  @moduledoc false

  @template_path "../../templates/controllers"

  @templates ["session.ex", "page_controller.ex"]

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, template])
    target = Path.join(["lib", web_snake_case, "controllers", template])
    Mix.Generator.copy_template(source, target, assigns, force: true)
    Code.format_file!(target)
  end
end
