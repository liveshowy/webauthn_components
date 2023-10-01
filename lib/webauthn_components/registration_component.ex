defmodule WebauthnComponents.RegistrationComponent do
  @moduledoc """
  A LiveComponent for registering a new Passkey via the WebAuthn API.

  > Registration = Sign Up

  Registration is the process of creating and associating a new key with a user account.

  Existing users may also register additional keys for backup, survivorship, sharing, or other purposes. Your application may set limits on how many keys are associated with an account based on business concerns.

  ## Assigns

  - `@user`: (**Required**) A `WebauthnComponents.WebauthnUser` struct.
  - `@challenge`: (Internal) A `Wax.Challenge` struct created by the component, used to create a new credential request in the client.
  - `@display_text` (Optional) The text displayed inside the button. Defaults to "Sign Up".
  - `@show_icon?` (Optional) Controls visibility of the key icon. Defaults to `true`.
  - `@class` (Optional) CSS classes for overriding the default button style.
  - `@disabled` (Optional) Set to `true` when the `SupportHook` indicates WebAuthn is not supported or enabled by the browser. Defaults to `false`.
  - `@id` (Optional) An HTML element ID.
  - `@require_resident_key` (Optional) Set to `false` to allow non-passkey credentials. Defaults to `true`.
  - `@relying_party` (Optional) URL to override the default RP value based on the origin. For example, the default may be `www.example.com`, and passing `example.com` would allow the credential to be used across subdomains, ie `mail.example.com`, `forum.example.com`, and so on.
    - If set, the same value must be passed to the `AuthenticationComponent`.

  ## Events

  The following events are handled internally by `RegistrationComponent`:

  - `"register"`: Triggered when a user clicks the `register` button.
  - `"registration-challenge"`: Sent from the component to the client to request credential registration for the endpoint URL.
  - `"registration-attestation"` Sent by the client when a registration attestation has been created.
  - `"error"` Sent by the client when an error occurs.

  ## Messages

  This component handles communication between the client, manages its own state, and communicates with the parent LiveView when registration is successful. Errors are also reported to the parent LiveView when the client pushes an error, or when registration fails.

  The following messages **must be handled by the parent LiveView** using [`Phoenix.LiveView.handle_info/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_info/2):

  - `{:registration_successful, key_id: raw_id, public_key: public_key}`
    - `:key_id` is a raw binary containing the credential id created by the browser.
    - `:public_key` is a map of raw binaries which may be used later for authentication.
    - These values must be persisted by the parent application in order to be used later during authentication.
  - `{:registration_failure, message: message}`
    - `:message` is an exception message returned by Wax when registration fails.
  - `{:error, payload}`
    - `payload` contains the `message`, `name`, and `stack` returned by the browser upon timeout or other client-side errors.

  Errors should be displayed to the user via [`Phoenix.LiveView.put_flash/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#put_flash/3). However, some errors may be too technical or cryptic to be useful to users, so the parent LiveView may paraphrase the message for clarity.
  """
  use Phoenix.LiveComponent
  import WebauthnComponents.IconComponents
  import WebauthnComponents.BaseComponents
  alias WebauthnComponents.WebauthnUser

  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:challenge, fn -> nil end)
      |> assign_new(:id, fn -> "registration-component" end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:webauthn_user, fn -> nil end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:require_resident_key, fn -> true end)
      |> assign_new(:display_text, fn -> "Sign Up" end)
      |> assign_new(:show_icon?, fn -> true end)
      |> assign_new(:relying_party, fn -> nil end)
    }
  end

  def update(%{webauthn_user: webauthn_user}, socket) do
    if is_struct(webauthn_user, WebauthnUser) do
      {
        :ok,
        socket
        |> assign(:webauthn_user, webauthn_user)
      }
    else
      send(self(), {:invalid_webauthn_user, webauthn_user})
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
    if !assigns[:app] do
      raise "`@app` is required"
    end

    ~H"""
    <span>
      <.button
        id={@id}
        phx-hook="RegistrationHook"
        phx-target={@myself}
        phx-click="register"
        class={@class}
        title="Create a new account"
        disabled={@disabled}
      >
        <span :if={@show_icon?} class="w-4 aspect-square opacity-70"><.icon_key /></span>
        <span><%= @display_text %></span>
      </.button>
    </span>
    """
  end

  def handle_event("register", _params, socket) do
    %{assigns: assigns, endpoint: endpoint, host_uri: host_uri} = socket

    %{
      app: app_name,
      id: id,
      require_resident_key: require_resident_key,
      webauthn_user: webauthn_user,
      relying_party: relying_party
    } = assigns

    if not is_struct(webauthn_user, WebauthnUser) do
      raise "user must be a WebauthnComponents.WebauthnUser struct."
    end

    attestation = "none"

    origin =
      case host_uri do
        %URI{} -> URI.to_string(host_uri)
        _ -> endpoint.url
      end

    rp_id = relying_party || :auto

    challenge =
      Wax.new_registration_challenge(
        attestation: attestation,
        origin: origin,
        rp_id: rp_id,
        trusted_attestation_types: [:none, :basic]
      )

    challenge_data = %{
      attestation: attestation,
      challenge: Base.encode64(challenge.bytes, padding: false),
      excludeCredentials: [],
      id: id,
      require_resident_key: require_resident_key,
      rp: %{
        id: challenge.rp_id,
        name: app_name
      },
      timeout: 60_000,
      user: webauthn_user
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event("registration-challenge", challenge_data)
    }
  end

  def handle_event("registration-attestation", payload, socket) do
    %{challenge: challenge, webauthn_user: webauthn_user} = socket.assigns

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
        key = %{key_id: raw_id, public_key: public_key}
        send(self(), {:registration_successful, key: key, webauthn_user: webauthn_user})

      {:error, error} ->
        message = Exception.message(error)
        send(self(), {:registration_failure, message: message})
    end

    {:noreply, socket}
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
