defmodule <%= inspect @web_pascal_case %>.SessionHooks.RequireUser do
  @moduledoc """
  Session hook for requiring an authenticated user.

  If `@current_user` is a `%User{}` struct, the socket may continue, otherwise the socket is redirected to the sign in page.

  This hook should follow `<%= inspect @web_pascal_case %>.SessionHooks.AssignUser` in a `Phoenix.LiveView.Router.live_session/3`.
  """
  alias <%= inspect @app_pascal_case %>.Users.User
  import Phoenix.LiveView
  use <%= inspect @web_pascal_case %>, :verified_routes

  def on_mount(:default, _params, _session, %{assigns: %{current_user: %User{}}} = socket) do
    {:cont, socket}
  end

  def on_mount(:default, _params, _session, socket) do
    {
      :halt,
      socket
      |> put_flash(:error, "Please sign in.")
      |> redirect(to: ~p"/sign-in")
    }
  end
end
