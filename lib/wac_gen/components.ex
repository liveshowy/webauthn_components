defmodule Wac.Gen.Components do
  @moduledoc false

  @template_path "../../templates/components"

  @template_files %{
    navigation_components: "navigation_components.ex",
    navbar: "navigation/navbar.html.heex",
    nav_link: "navigation/nav_link.html.heex",
    passkey_components: "passkey_components.ex",
    guidance: "passkeys/guidance.html.heex",
    token_form: "passkeys/token_form.html.heex"
  }

  @templates Map.keys(@template_files)

  def copy_templates(assigns) do
    for template <- @templates, do: copy_template(template, assigns)

    update_flash_component(assigns)
  end

  def copy_template(template, assigns) when template in @templates and is_list(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    file_name = @template_files[template]
    template_dir = Path.expand(@template_path, __DIR__)
    source = Path.join([template_dir, file_name])
    target = Path.join(["lib", web_snake_case, "components", file_name])

    if String.contains?(file_name, ".heex") do
      Mix.Generator.copy_file(source, target)
    else
      Mix.Generator.copy_template(source, target, assigns)
      Code.format_file!(target)
    end
  end

  def update_flash_component(assigns) do
    # This could use `Sourceror.Zipper`, but the AST for the component
    # and its `~H` would still require string replacement.
    # If the core components are revised or redesigned, this would fail silently.

    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    search_string = "fixed top-2 right-2 w-80"
    replacement_string = "fixed top-14 right-2 w-80"
    file_path = Path.join(["lib", web_snake_case, "components", "core_components.ex"])

    updated_content =
      file_path
      |> File.read!()
      |> String.replace(search_string, replacement_string)

    File.write!(file_path, updated_content)
  end
end
