defmodule <%= inspect @web_pascal_case %>.RegistrationLive do
  @moduledoc """
  LiveView for registering **new** users.

  See `WebauthnComponents` for details on Passkey authentication.
  """
  use <%= inspect @web_pascal_case %>, :live_view
  require Logger

  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias <%= inspect @app_pascal_case %>.Identity.UserToken

  alias WebauthnComponents.SupportComponent
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.WebauthnUser

  def mount(_params, _user_id, %{assigns: %{current_user: %User{}}} = socket) do
    {
      :ok,
      socket
      |> push_navigate(to: ~p"/", replace: true)
    }
  end

  def mount(_params, _session, socket) do
    webauthn_user = %WebauthnUser{id: generate_encoded_id(), name: nil, display_name: nil}

    if connected?(socket) do
      send_update(RegistrationComponent,
        id: "registration-component",
        webauthn_user: webauthn_user
      )
    end

    {
      :ok,
      socket
      |> assign(:page_title, "Sign Up")
      |> assign(:form, build_form())
      |> assign(:show_registration?, true)
      |> assign(:webauthn_user, webauthn_user)
      |> assign(:token_form, nil)
    }
  end

  def handle_event("update-form", %{"email" => email} = params, socket) do
    %{webauthn_user: webauthn_user} = socket.assigns

    webauthn_user =
      webauthn_user
      |> Map.put(:name, email)
      |> Map.put(:display_name, email)

    send_update(RegistrationComponent, id: "registration-component", webauthn_user: webauthn_user)

    {
      :noreply,
      socket
      |> assign(:form, build_form(params))
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
        |> assign(:form, nil)
      }
    end
  end

  def handle_info({:registration_successful, params}, socket) do
    %{form: form} = socket.assigns
    user_attrs = %{email: form[:email].value, keys: [params[:key]]}

    with {:ok, %User{id: user_id}} <- Identity.create(user_attrs),
         {:ok, %UserToken{value: token_value}} <- Identity.create_token(%{user_id: user_id}) do
      encoded_token = Base.encode64(token_value, padding: false)
      token_attrs = %{"value" => encoded_token}

      {
        :noreply,
        socket
        |> assign(:token_form, to_form(token_attrs, as: "token"))
      }
    else
      {:error, changeset} ->
        Logger.error(registration_error: {__MODULE__, changeset.changes, changeset.errors})

        {
          :noreply,
          socket
          |> assign(:form, to_form(changeset))
        }
    end
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

  defp build_form(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Map.put(:action, :insert)
    |> to_form()
  end

  defp generate_encoded_id do
    :crypto.strong_rand_bytes(64)
    |> Base.encode64(padding: false)
  end
end
