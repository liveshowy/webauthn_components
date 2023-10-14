defmodule <%= inspect @web_pascal_case %>.SessionHooks.RequireUser do
  @moduledoc """
  Session hook for requiring an authenticated user.

  If `@current_user` is a `%User{}` struct, the socket may continue, otherwise the socket is redirected to the sign in page.

  This hook should follow `<%= inspect @web_pascal_case %>.SessionHooks.AssignUser` in a `Phoenix.LiveView.Router.live_session/3`.

  ## Example

  ```
  # router.ex

  alias MyApp.SessionHooks.AssignUser
  alias MyApp.SessionHooks.RequireUser

  ...

  live_session :authenticated, on_mount: [AssignUser, RequireUser] do
    scope "/users", MyAppWeb do
      pipe_through :browser

      live "/profile", UserProfileLive
    end

    ...
  end
  ```
  """
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias Phoenix.LiveView.Socket
  import Phoenix.LiveView
  use <%= inspect @web_pascal_case %>, :verified_routes

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()} | {:halt, Socket.t()}
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
