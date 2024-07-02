defmodule <%= inspect @web_pascal_case %>.Session do
  @moduledoc """
  Manages user-authenticated sessions.
  """
  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  use <%= inspect @web_pascal_case %>, :controller

  def fetch_current_user(conn, _opts) do
    with encoded_value when is_binary(encoded_value) <- get_session(conn, :user_token),
         {:ok, decoded_value} <- Base.decode64(encoded_value, padding: false),
         {:ok, %User{id: user_id}} <- Identity.get_by_token(decoded_value) do
      conn
      |> put_session(:user_id, user_id)
    else
      _error ->
        conn
        |> renew_session()
    end
  end

  def create(conn, %{"value" => value}) do
    decoded_value = Base.decode64!(value, padding: false)

    case Identity.get_by_token(decoded_value, :session) do
      {:ok, %User{id: user_id}} ->
        conn
        |> put_session(:user_token, value)
        |> put_session(:user_id, user_id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/")

      {:error, _} ->
        conn
        |> renew_session()
        |> put_flash(:error, "Please sign in.")
        |> redirect(to: ~p"/sign-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> get_session("user_id")
    |> Identity.delete_all_user_sessions()

    conn
    |> renew_session()
    |> put_flash(:info, "Successfully signed out.")
    |> redirect(to: ~p"/")
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end
end
