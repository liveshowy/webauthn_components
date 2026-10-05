defmodule WebauthnComponents.AuthenticationComponent do
  @moduledoc """
  LiveComponent for validating the identity of a user with a WebAuthn credential.

  This component may be used when signing in a user to an existing account or re-authenticating during sensitive operations (user security changes, destructive admin actions, etc.).

  ## User Lookup

  After a user has approved client-side authentication, the component will pass a `t:WebauthnComponents.FindUser.t/0` message to the parent LiveView. The host application must locate the user, apply any relevant validation (eg. user status check), and send a list of credential tuples to the component. Each credential tuple must contain the credential id and public key so that the component can authorize the client-presented credential against the server-persisted credential.

  ## Autofill UI

  When `@mediation` is set to `:conditional` (default), the component will include a hidden input field which triggers an automatic user prompt to sign in with a Passkey. This makes the authentication process simpler for users by requiring fewer steps to sign in.

  To disable this behavior, set `@mediation` to one of the other [available values](https://developer.mozilla.org/en-US/docs/Web/API/CredentialsContainer/get#mediation).

  ## Example

  ```
  defmodule MyAppWeb.Authentication do
    ...
    
    def handle_info(%WebauthnComponents.FindUser{user_handle: user_id}, socket) do
      with {:ok, user} <- MyApp.Identity.get_user(user_id),
      %MyApp.Identity.User{status: :active, credentials: credentials} <- user do
        credential_tuples = Enum.map(credentials, &{&1.id, &1.public_key})
        send_update(WebauthnComponents.AuthenticationComponent,
          id: "authentication-component",
          credentials: credentials
          )
        
        {:noreply, socket}
      else
        {:error, reason} ->

          {
            :noreply,
            socket
            |> put_flash(:error, "Authentication failed")
          }
      end
    end
  end
  ```

  In the template, render the component:

  ```
  <.live_component
    id="authentication-component"
    module={WebauthnComponents.AuthenticationComponent}
    class="btn"
  >
    Sign in with a Passkey
  </.live_component>
  ```

  ## Resources

  - https://web.dev/articles/passkey-form-autofill
  """
  use Phoenix.LiveComponent
  alias WebauthnComponents.Config.PublicKeyCredentialRequestOptions
  alias WebauthnComponents.Config.PublicKeyCredential
  alias WebauthnComponents.Config.AuthenticatorAssertionResponse
  alias WebauthnComponents.FindUser

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:mediation, fn -> nil end)
      |> assign_new(:public_key_credential_request_options, fn ->
        %PublicKeyCredentialRequestOptions{}
      end)
    }
  end

  def render(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="AuthenticationHook"
      phx-click="authenticate"
      phx-target={@myself}
      disabled={@disabled}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
      <input
        :if={@mediation == :conditional}
        type="hidden"
        name="username"
        autocomplete="username webauthn"
        autofocus
      />
    </button>
    """
  end

  def update(%{mediation: :conditional}, socket) do
    {
      :ok,
      socket
      |> assign(:mediation, :conditional)
      |> get_credential()
    }
  end

  def update(%{credential_pairs: credential_pairs}, socket) do
    %{challenge: %Wax.Challenge{} = challenge, credential: %PublicKeyCredential{} = credential} =
      socket.assigns

    %PublicKeyCredential{
      id: id,
      response: %AuthenticatorAssertionResponse{
        authenticator_data: authenticator_data,
        signature: signature,
        client_data_json: client_data_json
      }
    } = credential

    with {:ok, credential_pairs} <- validate_credential_pairs(credential_pairs),
         {:ok, auth_data} <-
           Wax.authenticate(
             id,
             authenticator_data,
             signature,
             client_data_json,
             challenge,
             credential_pairs
           ),
         %Wax.AuthenticatorData{} <- auth_data do
      send(self(), {id, auth_data})
    else
      {:error, error} ->
        send(self(), error)
    end

    {
      :ok,
      socket
      |> assign(:challenge, nil)
      |> assign(:credential, nil)
    }
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("authenticate", _payload, socket) do
    {
      :noreply,
      socket
      |> get_credential()
    }
  end

  def handle_event("credential", credential, socket) do
    with {:ok, _challenge} <- fetch_challenge(socket.assigns),
         {:ok, key_id} <- Map.fetch(credential, "id"),
         {:ok, type} <- Map.fetch(credential, "type"),
         {:ok, authenticator_attachment} <- Map.fetch(credential, "authenticatorAttachment"),
         {:ok, response} <- Map.fetch(credential, "response"),
         {:ok, user_handle} <- Map.fetch(response, "userHandle"),
         {:ok, user_handle} <- Base.url_decode64(user_handle, padding: false),
         {:ok, authenticator_data} <- Map.fetch(response, "authenticatorData"),
         {:ok, client_data_json} <- Map.fetch(response, "clientDataJSON"),
         {:ok, signature} <- Map.fetch(response, "signature"),
         {:ok, key_id} <- Base.url_decode64(key_id, padding: false),
         {:ok, client_data_json} <- Base.url_decode64(client_data_json, padding: false),
         {:ok, authenticator_data} <- Base.url_decode64(authenticator_data, padding: false),
         {:ok, signature} <- Base.url_decode64(signature, padding: false) do
      send(self(), %FindUser{user_handle: user_handle})

      credential = %PublicKeyCredential{
        id: key_id,
        type: type,
        authenticator_attachment: authenticator_attachment,
        response: %AuthenticatorAssertionResponse{
          user_handle: user_handle,
          authenticator_data: authenticator_data,
          client_data_json: client_data_json,
          signature: signature
        }
      }

      {
        :noreply,
        socket
        |> assign(:credential, credential)
      }
    else
      :error ->
        send(self(), %Wax.InvalidAuthenticatorDataError{})
        {:noreply, assign(socket, :challenge, nil)}

      {:error, error} ->
        send(self(), error)
        {:noreply, assign(socket, :challenge, nil)}
    end
  end

  defp get_credential(socket) do
    %{
      id: id,
      mediation: mediation,
      public_key_credential_request_options:
        %PublicKeyCredentialRequestOptions{} = public_key_credential_request_options
    } = socket.assigns

    challenge =
      Wax.new_authentication_challenge(
        allow_credentials: public_key_credential_request_options.allow_credentials,
        origin: socket.endpoint.url(),
        rp_id: :auto,
        user_verification: public_key_credential_request_options.user_verification
      )

    publick_key = %PublicKeyCredentialRequestOptions{
      public_key_credential_request_options
      | challenge: challenge.bytes,
        rp_id: challenge.rp_id
    }

    socket
    |> assign(:challenge, challenge)
    |> push_event("get-credential", %{
      id: id,
      publicKey: publick_key,
      mediation: mediation
    })
  end

  defp fetch_challenge(%{challenge: %Wax.Challenge{} = challenge}) do
    {:ok, challenge}
  end

  defp fetch_challenge(_assigns), do: {:error, %Wax.ExpiredChallengeError{}}

  defp validate_credential_pairs(credentials) when is_list(credentials) do
    if Enum.all?(credentials, fn
         {id, public_key} -> is_binary(id) and is_map(public_key)
         _ -> false
       end) do
      {:ok, credentials}
    else
      {:error, :invalid_credentials}
    end
  end
end
