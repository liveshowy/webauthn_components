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
    <#{web_pascal_case}.navbar current_user={@current_user} />
    """
  end
end
