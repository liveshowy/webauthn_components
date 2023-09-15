defmodule Wac.Gen.AppHtml do
  @moduledoc false

  @header_regex ~r/\<header.*\<\/header\>/mis

  def update_app_html(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    file_path = Path.join(["lib", web_snake_case, "components", "layouts", "app.html.heex"])

    modified_file_contents =
      file_path
      |> File.read!()
      |> String.replace(@header_regex, navbar_component(assigns))

    File.write!(file_path, modified_file_contents)
  end

  defp navbar_component(assigns) do
    web_pascal_case = Keyword.fetch!(assigns, :web_pascal_case)

    """
    <#{inspect(web_pascal_case)}.NavigationComponents.navbar current_user={@current_user} />
    """
  end

  @flash_string "<.flash_group flash={@flash} />"

  def update_page_html(assigns) do
    web_snake_case = Keyword.fetch!(assigns, :web_snake_case)
    file_path = Path.join(["lib", web_snake_case, "controllers", "page_html", "home.html.heex"])
    home_link = home_link(assigns)
    injected_string = "#{@flash_string}\n#{home_link}"

    modified_file_contents =
      file_path
      |> File.read!()
      |> String.replace(@flash_string, injected_string)

    File.write!(file_path, modified_file_contents)
  end

  defp home_link(assigns) do
    web_pascal_case = Keyword.fetch!(assigns, :web_pascal_case)

    """
    <#{inspect(web_pascal_case)}.NavigationComponents.nav_link href={~p"/sign-in"}>
      Sign In
    </#{inspect(web_pascal_case)}.NavigationComponents.nav_link>
    """
  end
end
