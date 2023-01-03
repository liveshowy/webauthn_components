defmodule WebAuthnComponents.PasskeyComponent do
  @moduledoc """
  LiveComponent for interacting with Passkeys.

  > #### Caution {: .warning}
  >
  > This component should be considered in alpha status, with changes to the API, bugs, and incomplete documentation to be expected.
  >
  > It is **not** advisable to use this component in a production environment at this time.

  ## Overview

  "Passkey" is an end-user-friendly moniker for the WebAuthentication API, aka WebAuthn, where credentials may be used **across devices** through a cloud synchronization mechanism. Support for Passkeys requires integration with a user's operating system, browser, and device. It also requires Javascript to be enabled in the browser since WebAuthn is a browser API, where credential creation and verification is performed.

  Cloud synchronization is currently handled by the user's operating system - [Keychain](https://support.apple.com/guide/iphone/passkeys-passwords-devices-iph82d6721b2/ios) for MacOS users and [Google Password Manager](https://developers.google.com/identity/passkeys/supported-environments) for Android users. Third party services such as [1Password](https://www.future.1password.com/passkeys/) have also announced plans for Passkey support in upcoming releases.

  ## Terms

  - **Registration**: The process of creating a new credential to be used for a new account in your application.
  - **Authentication**: The process of using an existing credential to access an existing account in your application.

  ## A New Paradigm

  With Passkeys, it may be challenging (pardon the pun) to understand how registration and authentication are performed. The model differs from traditional username + password authentication in significant ways.

  This implementation of Passkeys takes advantage of userless or loginless authentication, where the user need not provide a username, email, password, or other data required for traditional registration. Instead, a UUID is provided to to the WebAuthn API along with other challenge data.

  ## Customization

  The registration and authentications processes are handled by this LiveComponent, which includes both a `Register` and `Authenticate` button.

  ## Communication

  Throughout the registration and authentication process, some messages must be passed to the parent LiveView. In the parent LiveView, use `handle_info/2` to accept the following messages:

  - `{:passkeys_supported, boolean}`: If false, an error should be displayed to the user.
  - `{:token_exists, token: token}`: Reports an existing session token. The parent application may decide whether to redirect to another view, clear the token, or render an error.
  - `{:token_stored, token: token}`:  Reports a token was successfully stored in the user's browser. The user should be redirected to another view at this point. For new users, it is recommended to proceed with profile setup since email and other details are not collected during registration.
  - `{:token_cleared}`: Reports that a token was successfully cleared. A message _may_ be displayed to the user if it makes sense to do so.
  - `{:registration_failure, message: message}`: Reports an error which should be displayed to the user. The parent application may display human-friendly verbiage instead, logging the error for internal debugging.
  - `{:find_credentials, user_handle: user_handle}`: Reports a `user_handle` is requesting authentication. The parent application must return a matching user, if one exists, in order to proceed with authentication.
  - `{:authentication_successful, key_id: raw_id, auth_data: auth_data}`: Reports the user was successfully authenticated by the WebAuthn API. The parent LiveView should create a new session token and pass it back to the component for persistence in the user's browser.
  - `{:authentication_failure, message: message}`: Reports the provided user could not be authenticated, with a message that may be displayed or paraphrased for the user.
  - `{:error, payload}`: Reports an error to the parent LiveView to be displayed or paraphrased for the user.

  Errors are reported and should typically be rendered to the user via flash messages and/or logged in the application's error tracking system for analysis. The component passes these messages to the LiveView to allow complete control over visibility, appearance, and wording of errors.

  ## Tokens

  TODO: Document token expectations and best practices.
  """
  require Logger
  use Phoenix.LiveComponent

  @button_class "px-2 py-1 border border-gray-300 dark:border-gray-600 hover:border-transparent bg-gray-200 hover:bg-blue-600 hover:text-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 transition rounded text-base shadow-sm flex gap-2 items-center hover:-translate-y-px hover:shadow-md"

  @div_class "flex gap-2 flex-wrap"

  @support_error_class "flex gap-2 items-center justify-center font-bold w-full border-2 border-rose-500 text-rose-600 dark:text-rose-200 bg-rose-200 dark:bg-rose-800 rounded-md shadow-md p-4 mb-4 transition"

  @timeout 60_000

  @doc """
  Mounts the component with default assigns.

  ## Configurable Assigns

  The following assigns may be passed to the component from your LiveView:

  - `@app`: _Required_ - The name of you application. May be a string or atom.
  - `@button_class`: Styles for buttons in the component.
  - `@div_class`: Styles for the `<div>` container for the buttons.
  - `@support_error_class`: Styles for the `<aside>` displayed when Passkeys are **not** supported.
  - `@timeout`: Milliseconds until registration and authentication prompts expire. This value is passed to the WebAuthn API.

  ## Internal Assigns

  Other assigns are set internally, but listed here for transparency:

  - `@passkeys_supported`: A boolean set to `true` when the Passkey LiveView hook detects WebAuthn support. Otherwise, it is set to `false`. The initial value is `nil`.
    - See [caniuse.com](https://caniuse.com/?search=webauthn) for browser support details.
  """
  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:passkeys_supported, fn -> nil end)
      |> assign_new(:button_class, fn -> @button_class end)
      |> assign_new(:div_class, fn -> @div_class end)
      |> assign_new(:support_error_class, fn -> @support_error_class end)
      |> assign_new(:timeout, fn -> @timeout end)
    }
  end

  @doc """
  Stores or clears a session token.

  When a `:token` assign is received, this function will either clear or store the user's token.

  - Assign `token: :clear` to remove a user's token.
  - Assign a binary token (typically a base64-encoded crypto hash) to persist a user's token to the browser's `sessionStorage`.
  - Invalid token assigns will be logged and the socket will be returned unchanged.
  """
  def update(%{token: token} = _assigns, socket) do
    cond do
      token == :clear ->
        {
          :ok,
          socket
          |> push_event("clear-token", %{token: token})
        }

      is_binary(token) ->
        {
          :ok,
          socket
          |> push_event("store-token", %{token: token})
        }

      true ->
        Logger.warn(invalid_token: token)
        {:ok, socket}
    end
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class={@div_class} phx-hook="PasskeyHook">
      <aside :if={@passkeys_supported == false} class={@support_error_class}>
        <span class="w-6 aspect-square opacity-70"><.icon_info_circle /></span>
        <span>Sorry, Passkeys are not supported by this browser.</span>
      </aside>

      <button
        phx-target={@myself}
        type="button"
        phx-click="register"
        class={@button_class}
        title="Create a new account"
        disabled={@passkeys_supported == false}
      >
        <span class="w-4 opacity-70"><.icon_key /></span>
        <span>Register</span>
      </button>

      <button
        phx-target={@myself}
        type="button"
        phx-click="authenticate"
        class={@button_class}
        title="Use an existing account"
        disabled={@passkeys_supported == false}
      >
        <span class="w-4 opacity-70"><.icon_key /></span>
        <span>Authenticate</span>
      </button>
    </div>
    """
  end

  def icon_key(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-full h-full"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z"
      />
    </svg>
    """
  end

  def icon_info_circle(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-full h-full"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
      />
    </svg>
    """
  end

  def handle_event("passkeys-supported", boolean, socket) do
    send(socket.root_pid, {:passkeys_supported, boolean})

    {
      :noreply,
      socket
      |> assign(:passkeys_supported, !!boolean)
    }
  end

  def handle_event("token-exists", payload, socket) do
    %{"token" => token} = payload
    send(socket.root_pid, {:token_exists, token: token})
    {:noreply, socket}
  end

  def handle_event("token-stored", payload, socket) do
    %{"token" => token} = payload
    send(socket.root_pid, {:token_stored, token: token})
    {:noreply, socket}
  end

  def handle_event("token-cleared", _payload, socket) do
    send(socket.root_pid, {:token_cleared})
    {:noreply, socket}
  end

  def handle_event("register", _params, socket) do
    %{endpoint: endpoint} = socket
    app_name = socket.assigns[:app]
    attestation = "none"

    user_handle = :crypto.strong_rand_bytes(64)

    user = %{
      id: Base.encode64(user_handle, padding: false),
      name: app_name,
      displayName: app_name
    }

    challenge =
      Wax.new_registration_challenge(
        attestation: attestation,
        origin: endpoint.url,
        rp_id: :auto,
        trusted_attestation_types: [:none, :basic]
      )

    challenge_data = %{
      attestation: attestation,
      challenge: Base.encode64(challenge.bytes, padding: false),
      excludeCredentials: [],
      rp: %{
        id: challenge.rp_id,
        name: app_name
      },
      timeout: 60_000,
      user: user
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> assign(:user_handle, user_handle)
      |> push_event("passkey-registration", challenge_data)
    }
  end

  def handle_event("registration-attestation", payload, socket) do
    %{challenge: challenge, user_handle: user_handle} = socket.assigns

    %{
      "attestation64" => attestation_64,
      "clientData" => client_data,
      "rawId64" => raw_id_64,
      "type" => "public-key"
    } = payload

    attestation = Base.decode64!(attestation_64, padding: false)
    raw_id = Base.decode64!(raw_id_64, padding: false)
    wax_response = Wax.register(attestation, client_data, challenge)

    case wax_response do
      {:ok, {authenticator_data, _result}} ->
        %{attested_credential_data: %{credential_public_key: public_key}} = authenticator_data

        send(
          socket.root_pid,
          {:registration_successful,
           key_id: raw_id, public_key: public_key, user_handle: user_handle}
        )

      {:error, error} ->
        message = Exception.message(error)
        send(socket.root_pid, {:registration_failure, message: message})
    end

    {:noreply, socket}
  end

  def handle_event("authenticate", _params, socket) do
    %{endpoint: endpoint} = socket
    %{timeout: timeout} = socket.assigns

    challenge =
      Wax.new_registration_challenge(
        origin: endpoint.url,
        rp_id: :auto,
        user_verification: "preferred"
      )

    challenge_data = %{
      challenge: Base.encode64(challenge.bytes, padding: false),
      timeout: timeout,
      rpId: challenge.rp_id,
      allowCredentials: challenge.allow_credentials,
      userVerification: challenge.user_verification
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event("passkey-authentication", challenge_data)
    }
  end

  def handle_event("authentication-attestation", payload, socket) do
    %{
      "authenticatorData64" => authenticator_data_64,
      "clientDataArray" => client_data_array,
      "rawId64" => raw_id_64,
      "signature64" => signature_64,
      "type" => type,
      "userHandle64" => user_handle_64
    } = payload

    authenticator_data = Base.decode64!(authenticator_data_64, padding: false)
    raw_id = Base.decode64!(raw_id_64, padding: false)
    signature = Base.decode64!(signature_64, padding: false)
    user_handle = Base.decode64!(user_handle_64, padding: false)

    attestation = %{
      authenticator_data: authenticator_data,
      client_data_array: client_data_array,
      raw_id: raw_id,
      signature: signature,
      type: type,
      user_handle: user_handle
    }

    send(socket.root_pid, {:find_credentials, user_handle: user_handle})

    {
      :noreply,
      socket
      |> assign(:attestation, attestation)
    }
  end

  def handle_event("user_credentials", payload, socket) do
    %{attestation: attestation, challenge: challenge} = socket.assigns

    %{
      authenticator_data: authenticator_data,
      client_data_array: client_data_array,
      raw_id: raw_id,
      signature: signature
    } = attestation

    %{credentials: credentials} = payload

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
        send(socket.root_pid, {:authentication_successful, key_id: raw_id, auth_data: auth_data})

      {:error, error} ->
        message = Exception.message(error)
        send(socket.root_pid, {:authentication_failure, message: message})
    end

    {:noreply, socket}
  end

  def handle_event("error", payload, socket) do
    send(socket.root_pid, {:error, payload})
    {:noreply, socket}
  end
end
