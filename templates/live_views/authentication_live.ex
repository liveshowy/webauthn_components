defmodule <%= inspect @web_pascal_case %>.AuthenticationLive do
  @moduledoc """
  LiveView for authenticating **existing** users.

  See `WebauthnComponents` for details on Passkey authentication.
  """
  use <%= inspect @web_pascal_case %>, :live_view
  require Logger

  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias <%= inspect @app_pascal_case %>.Identity.UserToken

  alias WebauthnComponents.SupportComponent
  alias WebauthnComponents.AuthenticationComponent

  def mount(_params, _user_id, %{assigns: %{current_user: %User{}}} = socket) do
    {
      :ok,
      socket
      |> push_navigate(to: ~p"/", replace: true)
    }
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:page_title, "Sign In")
      |> assign(:show_authentication?, true)
      |> assign(:token_form, nil)
    }
  end

  def handle_event(event, params, socket) do
    Logger.warning(unhandled_event: {__MODULE__, event, params})
    {:noreply, socket}
  end

  def handle_info({:passkeys_supported, supported?}, socket) do
    if supported? do
      {:noreply, socket}
    else
      {
        :noreply,
        socket
        |> put_flash(:error, "Passkeys are not supported in this browser.")
      }
    end
  end

  def handle_info({:find_credential, [key_id: key_id]}, socket) do
    case Identity.get_by_key_id(key_id) do
      {:ok, user} ->
        send_update(AuthenticationComponent, id: "authentication-component", user_keys: user.keys)

        {
          :noreply,
          socket
          |> assign(:user, user)
        }

      {:error, :not_found} ->
        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in")
          |> assign(:token_form, nil)
        }
    end
  end

  def handle_info({:authentication_successful, _auth_data}, socket) do
    %{user: user} = socket.assigns

    case Identity.create_token(%{user_id: user.id}) do
      {:ok, %UserToken{value: token_value}} ->
        encoded_token = Base.encode64(token_value, padding: false)
        token_attrs = %{"value" => encoded_token}

        {
          :noreply,
          socket
          |> assign(:token_form, to_form(token_attrs, as: "token"))
        }

      {:error, changeset} ->
        Logger.warning(authentication_error: {__MODULE__, changeset})

        {
          :noreply,
          socket
          |> put_flash(:error, "Failed to sign in")
          |> assign(:token_form, nil)
        }
    end
  end

  def handle_info({:authentication_failure, message: message}, socket) do
    Logger.error(authentication_error: {__MODULE__, message})

    {
      :noreply,
      socket
      |> put_flash(:error, "Failed to sign in")
      |> assign(:token_form, nil)
    }
  end

  def handle_info({:error, %{"message" => message, "name" => "NoUserVerifyingPlatformAuthenticatorAvailable"}}, socket) do
    socket
    |> assign(:token_form, nil)
    |> put_flash(:error, message)
    |> then(&{:noreply, &1})
  end

  def handle_info(message, socket) do
    Logger.warning(unhandled_message: {__MODULE__, message})
    {:noreply, socket}
  end
end
