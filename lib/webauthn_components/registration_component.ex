defmodule WebauthnComponents.RegistrationComponent do
  @moduledoc """
  LiveComponent for creating a new Webauthn credential for a user.

  This component may be used when signing up a new user or adding a new Passkey for an existing user.
  """
  use Phoenix.LiveComponent
  alias WebauthnComponents.Config.PublicKeyOptions

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:disabled, fn -> false end)
      |> assign_new(:class, fn -> nil end)
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:trusted_attestation_types, fn -> [:none, :basic] end)
    }
  end

  def render(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="RegistrationHook"
      phx-click="register"
      phx-target={@myself}
      disabled={@disabled}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  def handle_event("register", _params, socket) do
    %{
      id: id,
      public_key_options: %PublicKeyOptions{} = public_key_options,
      trusted_attestation_types: trusted_attestation_types
    } = socket.assigns

    challenge =
      Wax.new_registration_challenge(
        attestation: to_string(public_key_options.attestation),
        origin: socket.endpoint.url(),
        rp_id: :auto,
        trusted_attestation_types: trusted_attestation_types
      )

    public_key_options = %PublicKeyOptions{public_key_options | challenge: challenge.bytes}

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event("registration-challenge", %{id: id, publicKey: public_key_options})
    }
  end

  def handle_event("credential", credential, socket) do
    %{challenge: %Wax.Challenge{} = challenge} = socket.assigns

    credential =
      credential
      |> update_in(~w(response attestationObject), &Base.url_decode64!(&1, padding: false))
      |> update_in(~w(response clientDataJSON), &Base.url_decode64!(&1, padding: false))

    registration =
      Wax.register(
        credential["response"]["attestationObject"],
        credential["response"]["clientDataJSON"],
        challenge
      )

    case registration do
      {:ok, {%Wax.AuthenticatorData{} = authenticator_data, _result}} ->
        send(self(), authenticator_data)

      {:error, error} ->
        send(self(), error)
    end

    {:noreply, socket}
  end

  def handle_event("error", payload, socket) do
    send(self(), {:error, payload})
    {:noreply, socket}
  end
end
