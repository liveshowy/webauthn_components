defmodule WebauthnComponents.RegistrationComponent do
  @moduledoc """
  A LiveComponent for registering a new Passkey via the WebAuthn API.

  > Registration = Sign Up

  Registration is the process of creating and associating a new key with a user account.

  Existing users may also register additional keys for backup, survivorship, sharing, or other purposes. Your application may set limits on how many keys are associated with an account based on business concerns.

  ## Assigns

  - `@user`: (**Required**) A `WebauthnComponents.WebauthnUser` struct.
  - `@challenge`: (Internal) A `Wax.Challenge` struct created by the component, used to create a new credential request in the client.
  - `@app`: (**Required**) The name of your application or service. This is displayed to the user during registration.
  - `@authenticator_attachment` (Optional) The type of authenticator to use. Either `:platform` or `:cross_platform`. Defaults to `:platform`.
  - `@display_text` (Optional) The text displayed inside the "platform" button. Defaults to "Sign Up" if authenticator attachment is `:platform`, or "Sign Up With Connected Device" if `:cross_platform`.
  - `@display_text_class` (Optional) CSS classes for the display text span element.
  - `@icon_type` (Optional) The icon displayed inside the button. Either `:key` or `:usb`. Defaults to `:key` if authenticator attachment is `:platform`, or `:usb` if `:cross_platform`.
  - `@show_icon?` (Optional) Controls visibility of the key icon. Defaults to `true`.
  - `@class` (Optional) CSS classes for overriding the default button style.
  - `@disabled` (Optional) Set to `true` when the `SupportHook` indicates WebAuthn is not supported or enabled by the browser. Defaults to `false`.
  - `@id` (Optional) An HTML element ID.
  - `@timeout` (Optional) The timeout in milliseconds for the registration operation. Defaults to `60_000` (60 seconds).
  - `@resident_key` (Optional) Set to `:preferred` or `:discouraged` to allow non-passkey credentials. Defaults to `:required`.
  - `@check_uvpa_available` (Optional) Set to `true` to check if the user has a platform authenticator available. Defaults to `false`. See the User Verifying Platform Authenticator section for more information.
  - `@uvpa_error_message` (Optional) The message displayed when the user does not have a UVPA available. Defaults to "Registration unavailable. Your device does not support passkeys. Please install a passkey authenticator."

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

  ## User Verifying Platform Authenticator

  The User Verifying Platform Authenticator (UVPA) is a special type of authenticator that requires user verification.
  This is typically a biometric or PIN-based authenticator that is built into the platform, such as Touch ID or Windows Hello.

  When `@check_uvpa_available` is set to `true`, the component will check if the user has a UVPA available before allowing registration.
  If the user does not have a UVPA available, the component will disable the registration button and display a message indicating that the user must set up a UVPA before continuing.

  Example use case:
  The first/primary credential on a sensitive account may be required to come from a platform authenticator.
  Then, secondary credentials could be created from external devices.
  """
  use Phoenix.LiveComponent
  import WebauthnComponents.IconComponents
  alias WebauthnComponents.WebauthnUser

  def mount(socket) do
    {
      :ok,
      socket
      |> assign(:challenge, fn -> nil end)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:timeout, fn -> 60_000 end)
      |> assign_new(:webauthn_user, fn -> nil end)
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:resident_key, fn -> :required end)
      |> assign_new(:check_uvpa_available, fn -> false end)
      |> assign_new(:uvpa_error_message, fn ->
        "Registration unavailable. Your device does not support passkeys. Please install a passkey authenticator."
      end)
      |> assign_new(:show_icon?, fn -> true end)
      |> assign_new(:relying_party, fn -> nil end)
      |> assign_new(:display_text_class, fn -> nil end)
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
    socket
    |> assign(assigns)
    |> assign_new(:authenticator_attachment, fn -> :platform end)
    |> assign_authenticator_attachment_dependant_assigns()
    |> then(&{:ok, &1})
  end

  def render(assigns) do
    if !assigns[:app] do
      raise "`@app` is required"
    end

    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="RegistrationHook"
      phx-target={@myself}
      phx-click="register"
      data-check_uvpa_available={if @check_uvpa_available, do: "true"}
      data-uvpa_error_message={@uvpa_error_message}
      class={@class}
      title={@display_text}
      disabled={@disabled}
    >
      <span :if={@show_icon?} class="w-4 aspect-square opacity-70">
        <.icon type={@icon_type} />
      </span>
      <span class={@display_text_class}><%= @display_text %></span>
    </button>
    """
  end

  def handle_event("register", _params, socket) do
    %{assigns: assigns, endpoint: endpoint} = socket

    %{
      app: app_name,
      authenticator_attachment: authenticator_attachment,
      id: id,
      resident_key: resident_key,
      webauthn_user: webauthn_user,
      timeout: timeout
    } = assigns

    if not is_struct(webauthn_user, WebauthnUser) do
      raise "user must be a WebauthnComponents.WebauthnUser struct."
    end

    attestation = "none"

    challenge =
      Wax.new_registration_challenge(
        attestation: attestation,
        origin: endpoint.url(),
        rp_id: :auto,
        trusted_attestation_types: [:none, :basic]
      )

    authenticator_attachment_string =
      case authenticator_attachment do
        :platform -> "platform"
        :cross_platform -> "cross-platform"
      end

    challenge_data = %{
      "attestation" => attestation,
      "authenticatorAttachment" => authenticator_attachment_string,
      "challenge" => Base.encode64(challenge.bytes, padding: false),
      "excludeCredentials" => [],
      "id" => id,
      "residentKey" => resident_key,
      "requireResidentKey" => resident_key == :required,
      "rp" => %{
        "id" => challenge.rp_id,
        "name" => app_name
      },
      "timeout" => timeout,
      "user" => webauthn_user
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

  defp assign_authenticator_attachment_dependant_assigns(socket) do
    %{authenticator_attachment: authenticator_attachment} = socket.assigns

    socket
    |> assign_new(:id, fn -> default_id(authenticator_attachment) end)
    |> assign_new(:display_text, fn -> default_display_text(authenticator_attachment) end)
    |> assign_new(:icon_type, fn -> default_icon_type(authenticator_attachment) end)
  end

  defp default_id(authenticator_attachment) do
    "registration-component-#{authenticator_attachment}"
  end

  defp default_display_text(:platform) do
    "Sign Up With Passkey"
  end

  defp default_display_text(:cross_platform) do
    "Sign Up With Connected Device"
  end

  defp default_icon_type(:platform), do: :key
  defp default_icon_type(:cross_platform), do: :usb
end
