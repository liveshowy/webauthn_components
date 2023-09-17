defmodule PasskeysWeb.PageController do
  alias Hex.API.User
  alias <%= @app_pascal_case %>.Identity
  alias <%= @app_pascal_case %>.Identity.User
  use <%= @web_pascal_case %>, :controller

  def home(conn, _params) do
    with user_id when is_binary(user_id) <- get_session(conn, "user_id"),
         {:ok, %User{} = user} <- Identity.get(user_id) do
      conn
      |> assign(:current_user, user)
      |> render(:home, layout: false)
    else
      nil ->
        conn
        |> assign(:current_user, nil)
        |> render(:home, layout: false)

      {:error, :not_found} ->
        conn
        |> assign(:current_user, nil)
        |> render(:home, layout: false)
    end
  end
end
