defmodule WebauthnComponents.AuthenticationComponent do
  @moduledoc """
  A LiveComponent for authentication via WebAuthn API.

  > Authentication = Sign In

  Authentication is the process of matching a registered key to an existing user.

  See [USAGE.md](./USAGE.md) for example code.

  ## Assigns

  - `@challenge`: (Internal) A `Wax.Challenge` struct created by the component, used to request an existing credential in the client.
  - `@class` (Optional) CSS classes for overriding the default button style.
  - `@disabled` (Optional) Set to `true` when the `SupportHook` indicates WebAuthn is not supported or enabled by the browser. Defaults to `false`.
  - `@id` (Optional) An HTML element ID.

  ## Events

  - `"authenticate"`: Triggered when a user clicks the `authenticate` button.
  - `"authentication-challenge"`: Sent from the component to the client to request an existing credential registered to the endpoint URL.
  - `"authentication-attestation"`: Sent by the client when a credential has been registered to the endpoint URL and activated by the user.
  - `"error"` Sent by the client when an error occurs.

  ## Messages

  - `{:find_credentials, user_handle: user_handle}`
    - `user_handle` is a raw binary representing the user id or random id stored in the credential during registration.
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
      >
        <span class="w-4 opacity-70"><.icon_key /></span>
        <span>Authenticate</span>
      </.button>
    </span>
    """
  end

  def update(%{challenge: challenge, attestation: attestation, user_key: user_key} = assigns, socket) do
    %{
      authenticator_data: authenticator_data,
      client_data_array: client_data_array,
      # raw_id: raw_id,
      signature: signature,
      # user_handle: user_handle
    } = attestation

    %{
      key_id: key_id,
      # user_handle: user_handle,
      # public_key: public_key,
      user: user,
    } = user_key

    wax_response = Wax.authenticate(
      key_id,
      authenticator_data,
      signature,
      client_data_array,
      challenge,
      [user_key]
    )
    |> IO.inspect(label: :wax_authenticate)

    case wax_response do
      {:ok, _authenticator_data} ->
        send(self(), {:authentication_successful, user: user})
        {:ok, assign(socket, assigns)}

      {:error, error} ->
        message = Exception.message(error)
        send(self(), {:authentication_failure, message: message})
        {:ok, assign(socket, assigns)}
    end

  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("authenticate", _params, socket) do
    %{assigns: assigns, endpoint: endpoint} = socket
    %{id: id} = assigns

    challenge =
      Wax.new_authentication_challenge(
        origin: endpoint.url,
        rp_id: :auto,
        user_verification: "preferred",
        allow_credentials: []
      )

    challenge_data = %{
      challenge: Base.encode64(challenge.bytes, padding: false),
      id: id,
      rpId: challenge.rp_id,
      allowCredentials: challenge.allow_credentials,
      userVerification: challenge.user_verification
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event("authentication-challenge", challenge_data)
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

    send(self(), {:find_credentials, user_handle: user_handle})

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
