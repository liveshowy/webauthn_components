defmodule WebauthnComponents.RegistrationComponent do
  @moduledoc """
  LiveComponent for creating a new Webauthn credential for a user.

  This component may be used when signing up a new user or adding a new Passkey for an existing user.

  ## Credential Persistence

  Once a credential has been successfully created, this component will send a `t:Wax.AuthenticatorData.t/0` message to the parent LiveView.
  This struct contains data required to authenticate the user on subsequent visits, as well as some metadata from the authenticator device.

  The following example illustrates how a user and credential may be registered (some details omitted):

  ```
  # some_live_view.ex
  def handle_info(%Wax.AuthenticatorData{} = auth_data, socket) do
    %{form: form} = socket.assigns
    
    with {:ok, user} <- MyApp.Identity.register_user(form.source),
        {:ok, credential} <- MyApp.Identity.register_credential(user, auth_data) do
        {
          :noreply,
          socket
          |> put_flash(:info, "Welcome!")
          |> redirect()
          ...
        }
    end
  end
  ```

  The `:attested_credential_data` field contains a `t:Wax.AttestedCredentialData.t/0` struct.
  In this struct, the `:credential_id` and `:credential_public_key` fields must be persisted for future authentication.

  `WebauthnComponents` **defers to the host application** for persistence. 
  Whether the application follows CRUD or Event Sourcing patterns, it is recommended to define a schema dedicated to public key credential storage:

  ### CRUD Example

  ```
  defmodule MyApp.Identity.PublicKeyCredential do
    use Ecto.Schema
    alias Ecto.Changeset
    alias MyApp.Identity.User
    alias WebauthnComponents.CoseKey
    
    @primary_key {:id, binary, autogenerate: false}
    schema "public_key_credentials" do
      field :public_key, CoseKey
      belongs_to :user, User

      # Optional: Save `:flag_*` and other fields from `t:Wax.AuthenticatorData/0`
      field :flags, :map, default: %{}
      field :sign_count, :integer
      field :extensions, :map, default: %{}
    end

    def changeset(struct, params) do
      fields = __MODULE__.__schema__(:fields)
    
      struct
      |> Changeset.cast(params, fields)
      |> Changeset.validate_required([:id, :public_key])
      ...
    end
  end
  ```
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
        trusted_attestation_types: trusted_attestation_types,
        user_verification: to_string(public_key_options.authenticator_selection.user_verification)
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
    with {:ok, challenge} <- fetch_challenge(socket.assigns),
         {:ok, response} <- Map.fetch(credential, "response"),
         {:ok, attestation_object} <- Map.fetch(response, "attestationObject"),
         {:ok, client_data_json} <- Map.fetch(response, "clientDataJSON"),
         {:ok, attestation_object} <- Base.url_decode64(attestation_object, padding: false),
         {:ok, client_data_json} <- Base.url_decode64(client_data_json, padding: false),
         {:ok, {%Wax.AuthenticatorData{} = authenticator_data, _result}} <-
           Wax.register(attestation_object, client_data_json, challenge) do
      send(self(), authenticator_data)
    else
      :error -> send(self(), %Wax.InvalidAuthenticatorDataError{})
      {:error, error} -> send(self(), error)
      error -> send(self(), error)
    end

    {
      :noreply,
      socket
      |> assign(:challenge, nil)
    }
  end

  def handle_event("error", payload, socket) do
    send(self(), {:error, payload})
    {:noreply, socket}
  end

  def fetch_challenge(%{challenge: %Wax.Challenge{} = challenge}) do
    {:ok, challenge}
  end

  def fetch_challenge(_assigns), do: {:error, %Wax.ExpiredChallengeError{}}
end
