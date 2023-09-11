defmodule <%= inspect @web_pascal_case %>.Session do
  @moduledoc """
  Manages user-authenticated sessions.
  """
  alias <%= inspect @app_pascal_case %>.Users
  alias <%= inspect @app_pascal_case %>.Users.User
  use <%= inspect @web_pascal_case %>, :controller

  def fetch_current_user(conn, _opts) do
    with encoded_value when is_binary(encoded_value) <- get_session(conn, :user_token),
         {:ok, decoded_value} <- Base.decode64(encoded_value, padding: false),
         {:ok, %User{id: user_id}} <- Users.get_by_token(decoded_value) do
      conn
      |> put_session(:user_id, user_id)
    else
      _error ->
        conn
        |> clear_session()
    end
  end

  def create(conn, %{"value" => value}) do
    decoded_value = Base.decode64!(value, padding: false)

    case Users.get_by_token(decoded_value, :session) do
      {:ok, %User{id: user_id}} ->
        conn
        |> put_session(:user_token, value)
        |> put_session(:user_id, user_id)
        |> redirect(to: ~p"/")

      {:error, _} ->
        conn
        |> clear_session()
        |> redirect(to: ~p"/sign-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> get_session("user_id")
    |> Users.delete_all_user_sessions()

    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
