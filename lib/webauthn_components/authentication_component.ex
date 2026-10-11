defmodule WebauthnComponents.AuthenticationComponent do
  @moduledoc """
  LiveComponent for authenticating a user with a WebAuthn credential.

  Use this component to sign in an existing user or to re-authenticate during sensitive operations (security changes, destructive admin actions, and so on).

  ## Assigns

  - `@id` (Required) An HTML element ID.
  - `@mediation` (Optional) `"optional"` (default) or `"conditional"`.
  - `@disabled` (Optional) Disables the button. Defaults to `false`.
  - `@class` (Optional) CSS classes for the button.
  - `@rest` (Optional) Additional HTML attributes for the button.
  - `@public_key_credential_request_options` (Optional) A `WebauthnComponents.PublicKeyCredentialRequestOptions` struct controlling the request (for example, `:timeout`, `:user_verification`, and `:allow_credentials`).

  ## Messages

  - `%WebauthnComponents.FindUser{}` — the user presented a credential. Reply with `send_update(WebauthnComponents.AuthenticationComponent, id: ..., credentials: credentials)`.
  - `{credential_id, %Wax.AuthenticatorData{}}` — the credential was verified. `credential_id` is the raw credential id.
  - `{:error, payload}` — a client-side error. `payload` contains the `message`, `name`, and `stack` reported by the browser.
  - A `Wax` error struct (for example, `%Wax.InvalidClientDataError{}`) — server-side verification failed.

  ## User Lookup

  After the user approves authentication in the browser, the component sends a `t:WebauthnComponents.FindUser.t/0` message to the parent LiveView.
  The host application must locate the user, apply any relevant validation (for example, an account-status check), and send the user's credentials back with `Phoenix.LiveView.send_update/3`.
  Each credential must expose a credential id and public key; by default the component reads the `:id` and `:public_key` fields from any struct or map.
  Define an implementation of `WebauthnComponents.CredentialProtocol` when your schema uses different field names.

  ## Conditional UI

  Set `@mediation` to `"conditional"` to render a hidden input that lets the browser offer a Passkey while the user interacts with the page, reducing the number of steps required to sign in.

  For best results, use `WebauthnComponents.ClientCapabilitiesComponent` to detect browser support, then update `@mediation` with the appropriate value.

  ```
  # MyAppWeb.Authentication template
  <.live_component
    module={WebauthnComponents.ClientCapabilitiesComponent}
    id="client-capabilities-component"
  />

  <.live_component
    module={WebauthnComponents.AuthenticationComponent}
    id="authentication-component"
    class="btn btn-primary w-full"
  >
    <span>Log in with a Passkey</span>
  </.live_component>
  ```

  ```
  defmodule MyAppWeb.Authentication do
    ...

    def handle_info({:client_capabilities, capabilities}, socket) do
      if capabilities["conditionalGet"] do
        send_update(WebauthnComponents.AuthenticationComponent,
          id: "authentication-component",
          mediation: "conditional"
        )
      end

      {:noreply, socket}
    end
  end
  ```

  ## Example

  ```
  defmodule MyAppWeb.Authentication do
    ...

    def handle_info(%WebauthnComponents.FindUser{user_handle: user_handle}, socket) do
      with {:ok, user} <- MyApp.Identity.get_user(user_handle),
           %MyApp.Identity.User{status: :active, credentials: credentials} <- user do
        send_update(WebauthnComponents.AuthenticationComponent,
          id: "authentication-component",
          credentials: credentials
        )

        {:noreply, socket}
      else
        error ->
          Logger.warning(error)
          
          {
            :noreply,
            socket
            |> put_flash(:error, "Authentication failed")
          }
      end
    end

    def handle_info({_credential_id, %Wax.AuthenticatorData{}}, socket) do
      # Authentication succeeded. Sign the user in.
      {:noreply, socket}
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
  - https://developer.mozilla.org/en-US/docs/Web/API/CredentialsContainer/get#mediation
  - https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API#discoverable_and_non-discoverable_credentials
  """
  use Phoenix.LiveComponent
  alias WebauthnComponents.PublicKeyCredentialRequestOptions
  alias WebauthnComponents.PublicKeyCredential
  alias WebauthnComponents.AuthenticatorAssertionResponse
  alias WebauthnComponents.FindUser
  alias WebauthnComponents.CredentialProtocol

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:mediation, fn -> "optional" end)
      |> assign_new(:public_key_credential_request_options, fn ->
        %PublicKeyCredentialRequestOptions{}
      end)
    }
  end

  def render(assigns) do
    ~H"""
    <span class="contents">
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
      </button>
      <input
        :if={@mediation == "conditional"}
        type="hidden"
        name="webauthn"
        autocomplete="webauthn"
        autofocus
      />
    </span>
    """
  end

  def update(%{mediation: "conditional"}, socket) do
    {
      :ok,
      socket
      |> assign(:mediation, "conditional")
      |> get_credential()
    }
  end

  def update(%{credentials: credentials}, socket) when is_list(credentials) do
    case socket.assigns do
      %{
        challenge: %Wax.Challenge{} = challenge,
        credential: %PublicKeyCredential{} = credential
      } ->
        verify_credentials(socket, challenge, credential, credentials)

      _assigns ->
        send(self(), %Wax.InvalidAuthenticatorDataError{})
        {:ok, socket}
    end
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

  def handle_event("credential", credential, socket) when is_map(credential) do
    with {:ok, _challenge} <- fetch_challenge(socket.assigns),
         {:ok, key_id} <- Map.fetch(credential, "id"),
         {:ok, type} <- Map.fetch(credential, "type"),
         {:ok, authenticator_attachment} <- Map.fetch(credential, "authenticatorAttachment"),
         {:ok, response} <- Map.fetch(credential, "response"),
         {:ok, user_handle} <- Map.fetch(response, "userHandle"),
         {:ok, user_handle} <- decode_user_handle(user_handle),
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

      {:noreply, assign(socket, :credential, credential)}
    else
      {:error, %Wax.ExpiredChallengeError{} = error} ->
        send(self(), error)
        {:noreply, assign(socket, :challenge, nil)}

      _other ->
        send(self(), %Wax.InvalidAuthenticatorDataError{})
        {:noreply, assign(socket, :challenge, nil)}
    end
  end

  def handle_event("credential", _payload, socket) do
    send(self(), %Wax.InvalidAuthenticatorDataError{})
    {:noreply, assign(socket, :challenge, nil)}
  end

  def handle_event("error", payload, socket) do
    send(self(), {:error, payload})
    {:noreply, socket}
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
        origin: socket.endpoint.url(),
        rp_id: :auto,
        user_verification: to_string(public_key_credential_request_options.user_verification)
      )

    public_key = %PublicKeyCredentialRequestOptions{
      public_key_credential_request_options
      | challenge: challenge.bytes,
        rp_id: challenge.rp_id
    }

    socket
    |> assign(:challenge, challenge)
    |> push_event("get-credential", %{
      id: id,
      publicKey: public_key,
      mediation: mediation
    })
  end

  defp fetch_challenge(%{challenge: %Wax.Challenge{} = challenge}) do
    {:ok, challenge}
  end

  defp fetch_challenge(_assigns), do: {:error, %Wax.ExpiredChallengeError{}}

  defp decode_user_handle(user_handle) when is_binary(user_handle) do
    Base.url_decode64(user_handle, padding: false)
  end

  defp decode_user_handle(_user_handle), do: :error

  defp verify_credentials(socket, challenge, credential, credentials) do
    %PublicKeyCredential{
      id: id,
      response: %AuthenticatorAssertionResponse{
        authenticator_data: authenticator_data,
        signature: signature,
        client_data_json: client_data_json
      }
    } = credential

    with {:ok, credential_pairs} <- get_credential_pairs(credentials),
         {:ok, %Wax.AuthenticatorData{} = auth_data} <-
           Wax.authenticate(
             id,
             authenticator_data,
             signature,
             client_data_json,
             challenge,
             credential_pairs
           ) do
      send(self(), {id, auth_data})
    else
      {:error, error} -> send(self(), error)
    end

    {:ok, socket |> assign(:challenge, nil) |> assign(:credential, nil)}
  end

  defp get_credential_pairs(credentials) do
    try do
      for credential <- credentials do
        {CredentialProtocol.id(credential), CredentialProtocol.public_key(credential)}
      end
      |> then(&{:ok, &1})
    rescue
      error -> {:error, error}
    end
  end
end
