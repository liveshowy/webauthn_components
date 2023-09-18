defmodule <%= inspect @web_pascal_case %>.SessionHooks.AssignUser do
  @moduledoc """
  Session hook for setting the `@current_user` assign on the socket.

  If a **valid** `user_id` or `user_token` is set in the session, the user will be assigned, otherwise `@current_user` will be `nil`.

  ## Example

  ```
  # router.ex

  alias MyApp.SessionHooks.AssignUser

  ...

  live_session :default, on_mount: [AssignUser] do
    scope "/", MyAppWeb do
      pipe_through :browser

      live "/sign-in", AuthenticationLive
    end
  end
  ```
  """
  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias Phoenix.LiveView.Socket
  import Phoenix.Component

  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()} | {:halt, Socket.t()}
  def on_mount(:default, _params, _session, %{assigns: %{current_user: %User{}}} = socket) do
    {:cont, socket}
  end

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    case Identity.get(user_id) do
      {:ok, %User{} = user} ->
        {
          :cont,
          socket
          |> assign(:current_user, user)
        }

      _ ->
        {
          :cont,
          socket
          |> assign(:current_user, nil)
        }
    end
  end

  def on_mount(:default, _params, %{"user_token" => user_token}, socket) do
    case Identity.get_by_token(user_token) do
      {:ok, %User{} = user} ->
        {
          :cont,
          socket
          |> assign(:current_user, user)
        }

      _ ->
        {
          :cont,
          socket
          |> assign(:current_user, nil)
        }
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {
      :cont,
      socket
      |> assign(:current_user, nil)
    }
  end
end
