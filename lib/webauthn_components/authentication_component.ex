defmodule WebauthnComponents.AuthenticationComponent do
  @moduledoc """
  A LiveComponent for authentication via WebAuthn API.

  > Authentication = Sign In

  Authentication is the process of matching a registered key to an existing user.

  With Passkeys, the user is presented with a native modal from the browser or OS.

  - If the user has only one passkey registered to the application's origin URL, they will be prompted to confirm acceptance via biometric ID (touch, face, etc.), OS password, or an OS PIN.
  - If multiple accounts are registered to the device for the origin URL, the user may select an account to use for the current session.

  ## Cross-Device Authentication

  When a user attempts to authenticate on a device where their Passkey is **not** stored, they may scan a QR code to use a cloud-sync'd Passkey.

  ### Example

  Imagine a user, Amal, registers a Passkey for example.com on their iPhone and it's stored in iCloud. When they attempt to sign into example.com on a non-Apple device or any browser which cannot access their OS keychain, they may choose to scan a QR code using their iPhone. Assuming the prompts on the iPhone are successful, the other device will be authenticated using the same web account which was initially registered on the iPhone.

  While this example refers to Apple's Passkey implementation, the process on other platforms may vary. Cross-device credential managers like 1Password may provide a more seamless flow for users who are not constrained to one OS or browser.

  ## Assigns

  - `@challenge` (Internal) A `Wax.Challenge` struct created by the component, used to request an existing credential in the client.
  - `@display_text` (Optional) The text displayed inside the button. Defaults to "Sign In".
  - `@show_icon?` (Optional) Controls visibility of the key icon. Defaults to `true`.
  - `@class` (Optional) CSS classes for overriding the default button style.
  - `@disabled` (Optional) Set to `true` when the `SupportHook` indicates WebAuthn is not supported or enabled by the browser. Defaults to `false`.
  - `@id` (Optional) An HTML element ID.
  - `@skip_conditional_ui_check` (Optional) Set to `true` to skip the conditional UI check for Passkey autofill. Defaults to `false`.

  If the authenticator is not supporting resident keys you have to provide a list of `%WebauthnCredentials{}` either by using:
  - `@user` (Optional) A user identifier like e-mail or user name as a string
  - `@retrieve_credentials_function` (Optional) A function of the type `@spec retrieve_credentials_for(binary) :: [%WebauthnCredential{}]` which is supposed to get the IDs and the public keys for a given user

  or

  - `@allow_credentials` (Optional) A list of `%WebauthnCredentials{}`

  ## Events

  - `"authenticate"`: Triggered when a user clicks the `authenticate` button.
  - `"authentication-challenge"`: Sent from the component to the client to request an existing credential registered to the endpoint URL.
  - `"authentication-attestation"`: Sent by the client when a credential has been registered to the endpoint URL and activated by the user.
  - `"error"` Sent by the client when an error occurs.

  ## Messages

  - `{:find_credential, key_id: key_id}`
    - `key_id` is a raw binary representing the id stored associated with the credential in both the client and server during registration.
    - The parent LiveView must successfully lookup the user with this data before storing a token and redirecting to another view.
  - `{:error, payload}`
    - `payload` contains the `message`, `name`, and `stack` returned by the browser upon timeout or other client-side errors.

    Errors should be displayed to the user via [`Phoenix.LiveView.put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3). However, some errors may be too technical or cryptic to be useful to users, so the parent LiveView may paraphrase the message for clarity.
  """
  use Phoenix.LiveComponent
  import WebauthnComponents.IconComponents
  import WebauthnComponents.BaseComponents

  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:challenge, fn -> nil end)
      |> assign_new(:id, fn -> "authentication-component" end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:disabled, fn -> nil end)
      |> assign_new(:display_text, fn -> "Sign In" end)
      |> assign_new(:show_icon?, fn -> true end)
      |> assign_new(:relying_party, fn -> nil end)
      |> assign_new(:allow_credentials, fn -> [] end)
      |> assign_new(:user, fn -> nil end)
      |> assign_new(:retrieve_credentials_function, fn -> nil end)
      |> assign_new(:skip_conditional_ui_check, fn -> false end)
    }
  end

  def render(assigns) do
    ~H"""
    <span>
      <.button
        id={@id}
        phx-hook="AuthenticationHook"
        phx-target={@myself}
        type="button"
        phx-click="authenticate"
        class={@class}
        title="Use an existing account"
        disabled={@disabled}
        data-skip-conditional-ui-check={if @skip_conditional_ui_check, do: "true"}
      >
        <span :if={@show_icon?} class="aspect-square w-4 opacity-70"><.icon_key /></span>
        <span>{@display_text}</span>
      </.button>

      <input type="hidden" autocomplete="webauthn" />
    </span>
    """
  end

  def update(%{user_keys: user_keys} = assigns, socket) do
    %{challenge: challenge, attestation: attestation} = socket.assigns

    %{
      authenticator_data: authenticator_data,
      client_data_array: client_data_array,
      raw_id: raw_id,
      signature: signature
    } = attestation

    credentials = Enum.map(user_keys, &{&1.key_id, &1.public_key})

    wax_response =
      Wax.authenticate(
        raw_id,
        authenticator_data,
        signature,
        client_data_array,
        challenge,
        credentials
      )

    case wax_response do
      {:ok, auth_data} ->
        send(self(), {:authentication_successful, auth_data})
        {:ok, assign(socket, assigns)}

      {:error, %{message: message}} ->
        send(self(), {:authentication_failure, message: message})
        {:ok, assign(socket, assigns)}

      {:error, error} ->
        send(self(), {:authentication_failure, message: error})
        {:ok, assign(socket, assigns)}
    end
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("authenticate", params, socket) do
    %{assigns: assigns, endpoint: endpoint} = socket

    %{
      id: id,
      allow_credentials: allow_credentials,
      retrieve_credentials_function: retrieve_credentials_function,
      user: user
    } = assigns

    supports_passkey_autofill = Map.has_key?(params, "supports_passkey_autofill")

    event =
      if supports_passkey_autofill,
        do: "authentication-challenge-with-conditional-ui",
        else: "authentication-challenge"

    # If both, a function and a user are supplied, call that function to retrieve the credentials for
    # the given user
    # Otherwise: use the allow_credential list which might be preset instead
    credentials =
      if is_nil(retrieve_credentials_function) and is_nil(user) do
        allow_credentials
      else
        retrieve_credentials_function.(user)
      end

    challenge =
      Wax.new_authentication_challenge(
        # WAX_ expects a list of maps, we have been using structs to do the xfer: So convert back
        allow_credentials:
          for credential <- credentials do
            {credential.id, credential.public_key}
          end,
        origin: endpoint.url(),
        rp_id: :auto,
        user_verification: "preferred"
      )

    allow_credentials_ids = Enum.map(credentials, &Base.encode64(&1.id))

    challenge_data = %{
      challenge: Base.encode64(challenge.bytes, padding: false),
      id: id,
      rpId: challenge.rp_id,
      allowCredentialsIDs: allow_credentials_ids,
      userVerification: challenge.user_verification
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event(event, challenge_data)
    }
  end

  def handle_event("authentication-attestation", payload, socket) do
    %{
      "authenticatorData64" => authenticator_data_64,
      "clientDataArray" => client_data_array,
      "rawId64" => raw_id_64,
      "signature64" => signature_64,
      "type" => type
    } = payload

    authenticator_data = Base.decode64!(authenticator_data_64, padding: false)
    raw_id = Base.decode64!(raw_id_64, padding: false)
    signature = Base.decode64!(signature_64, padding: false)

    attestation = %{
      authenticator_data: authenticator_data,
      client_data_array: client_data_array,
      raw_id: raw_id,
      signature: signature,
      type: type
    }

    send(self(), {:find_credential, key_id: raw_id})

    {
      :noreply,
      socket
      |> assign(:attestation, attestation)
    }
  end

  def handle_event("error", payload, socket) do
    send(self(), {:error, payload})
    {:noreply, socket}
  end

  def handle_event(event, payload, socket) do
    send(self(), {:invalid_event, event, payload})
    {:noreply, socket}
  end
end
