defmodule WebAuthnLiveComponent do
  @moduledoc """
  A LiveComponent for passwordless authentication via WebAuthn.
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import Phoenix.LiveView.Helpers
  alias Ecto.Changeset
  require Logger

  # prop app, :atom, required: true
  # prop changeset, :struct, default: build_changeset()
  # prop username, :string
  # prop params, :map
  # prop css_class, :css_class
  # prop register_label, :string
  # prop authenticate_label, :string
  # prop user, :struct

  @doc """
  Ensure required assigns are present, falling back to default values where necessary.
  """
  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:changeset, &build_changeset/1)
      |> assign_new(:css_class, fn -> "grid gap-2 grid-cols-2" end)
      |> assign_new(:register_label, fn -> "Sign Up" end)
      |> assign_new(:authenticate_label, fn -> "Sign In" end)
    }
  end

  @doc """
  Render the WebAuthn form.
  """
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        let={form}
        for={@changeset}
        as={:auth}
        id={@id}
        class={@css_class}
        phx-change="change"
        phx-submit="authenticate"
        phx-target={@myself}
        phx-hook="WebAuthn"
      >
        <%= if !Enum.empty?(@changeset.errors) do %>
          <h2>Errors</h2>
          <ul>
            <%= for {field, {error, _meta}} <- @changeset.errors do %>
              <li>
                <strong><%= field %></strong> <%= error %>
              </li>
            <% end %>
          </ul>
        <% end %>

        <%= label form, :username, class: "col-span-full" %>
        <%= text_input form,
          :username,
          class: "col-span-full",
          "phx-debounce": 500,
          autofocus: true
        %>

        <button
          type="button"
          value="authenticate"
          phx-click="authenticate"
          phx-target={@myself}
        >
            <%= @authenticate_label %>
        </button>

        <button
          type="button"
          value="register"
          phx-click="register"
          phx-target={@myself}
        >
            <%= @register_label %>
        </button>
      </.form>
    </div>
    """
  end

  @doc """
  Handlers for server and client events.

  ## Server-Side Events

  The following events are triggered by the rendered form:

  - `"change"` - Form data has changed.
  - `"register"` - The user wants to create a new account.
  - `"authenticate"` - The user wants to sign in as an existing user.

  While the `change` event handler extracts data from the params argument, `register` and `authenticate` ignore the params argument, pulling state from the socket assigns instead.

  ## Client-Side Events

  `WebAuthnLiveComponent` uses a Javascript (JS) hook to interact with the client-side WebAuthn API.

  The following events are triggered by the WebAuthn JS hook:

  - `"webauthn_supported"` - The JS hook as reported whether webauthn is supported.
  - `"user_token"` - A token stored in the client's `sessionStorage`.
  - `"register_attestation"` - A WebAuthn registration attestation created by the client.
  - `"authenticate_attestation"` - A WebAuthn authentication attestation created by the client.
  """
  def handle_event(event, params, socket)

  def handle_event("webauthn_supported", boolean, socket) do
    socket =
      if boolean == false do
        put_flash(socket, :error, "WebAuthn is not supported")
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("user_token", token, socket) do
    send(socket.root_pid, {:user_token, token: token})
    {:noreply, socket}
  end

  def handle_event("change", params, socket) do
    %{"auth" => %{"username" => username}} = params

    changeset =
      %{params: %{username: username}}
      |> build_changeset()
      |> add_changeset_requirements()

    {
      :noreply,
      socket
      |> assign(:changeset, changeset)
    }
  end

  def handle_event("register", _params, socket) do
    %{assigns: %{changeset: changeset, app: app}} = socket
    %{changes: %{username: username}} = changeset

    new_changeset =
      %{params: %{username: username}}
      |> build_changeset()
      |> add_changeset_requirements()

    challenge =
      socket
      |> get_origin()
      |> build_registration_challenge()

    challenge_data = map_registration_challenge_data(challenge, app: app, username: username)
    Logger.info(registration_challenge_sent: username)

    {
      :noreply,
      socket
      |> assign(:changeset, new_changeset)
      |> assign(:challenge, challenge)
      |> push_event("registration_challenge", challenge_data)
    }
  end

  def handle_event("register_attestation", params, socket) do
    %{assigns: %{changeset: changeset, challenge: challenge}} = socket

    %{
      "attestation64" => attestation_64,
      "clientData" => client_data,
      "rawId64" => raw_id_64,
      "type" => "public-key"
    } = params

    user = changeset.changes
    attestation = Base.decode64!(attestation_64, padding: false)
    {:ok, {authenticator_data, _result}} = Wax.register(attestation, client_data, challenge)
    %{attested_credential_data: %{credential_public_key: public_key}} = authenticator_data
    user_key = %{key_id: raw_id_64, public_key: public_key}

    # Send a message to the parent LiveView process, where the user may be persisted.
    send(socket.root_pid, {:register_user, user: user, key: user_key})
    Logger.info(registration_attestation_received: {__MODULE__, user.username})

    {:noreply, socket}
  end

  def handle_event("authenticate", _params, socket) do
    %{assigns: %{changeset: changeset}} = socket
    %{changes: %{username: username}} = changeset

    new_changeset =
      %{params: %{username: username}}
      |> build_changeset()
      |> add_changeset_requirements()

    # Send message to parent LiveView requesting a user lookup.
    send(socket.root_pid, {:find_user_by_username, username: username})
    Logger.info(finding_user: {__MODULE__, username})

    {
      :noreply,
      socket
      |> assign(:changeset, new_changeset)
    }
  end

  def handle_event("authenticate_attestation", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("error", params, socket) do
    send(socket.root_pid, {:error, {params}})
    {:noreply, socket}
  end

  def handle_event(event, payload, socket) do
    Logger.warning(unhandled_event: {__MODULE__, event, payload})
    {:noreply, socket}
  end

  @doc """
  `update/2` is used here to catch the `found_user` assign once it's placed by the parent LiveView.
  """
  def update(%{found_user: user} = assigns, socket) do
    Logger.info(user_found: {__MODULE__, user.username})

    %{
      allowed_credentials: allowed_credentials,
      key_ids: key_ids
    } = get_credential_map(user)

    challenge_opts = [
      attestation: "none",
      origin: get_origin(socket),
      rp_id: :auto
    ]

    challenge = build_authentication_challenge(allowed_credentials, challenge_opts)
    challenge_data = map_authentication_challenge_data(challenge, key_ids: key_ids)
    Logger.info(authentication_challenge_sent: {__MODULE__, user.username})

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:challenge, challenge)
      |> push_event("authentication_challenge", challenge_data)
    }
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end

  defp build_changeset(assigns) do
    user = Map.get(assigns, :user, %{})
    types = %{username: :string}
    params = Map.get(assigns, :params, %{username: ""})

    {user, types}
    |> Changeset.cast(params, Map.keys(types))
  end

  defp add_changeset_requirements(changeset) do
    changeset
    |> Changeset.validate_required([:username])
    |> Changeset.validate_length(:username, min: 3, max: 40)
  end

  defp build_registration_challenge(origin) do
    Wax.new_registration_challenge(
      attestation: "none",
      origin: origin,
      rp_id: :auto
    )
  end

  defp map_registration_challenge_data(%Wax.Challenge{} = challenge, opts) do
    [app: app, username: username] = opts
    authenticator_attachment = Keyword.get(opts, :authenticator_attachment)

    %{
      appName: app,
      attestation: challenge.attestation,
      authenticator_attachment: authenticator_attachment,
      challenge_64: Base.encode64(challenge.bytes, padding: false),
      rp_id: challenge.rp_id,
      user: %{name: username, displayName: username},
      user_verification: challenge.user_verification
    }
  end

  defp build_authentication_challenge(allowed_credentials, challenge_opts) do
    Wax.new_authentication_challenge(allowed_credentials, challenge_opts)
  end

  defp map_authentication_challenge_data(%Wax.Challenge{} = challenge, key_ids: key_ids) do
    %{
      attestation: challenge.attestation,
      challenge_64: Base.encode64(challenge.bytes, padding: false),
      key_ids_64: key_ids,
      user_verification: challenge.user_verification
    }
  end

  defp get_origin(socket) do
    %{scheme: scheme, host: host} = socket.host_uri
    "#{scheme}://#{host}"
  end

  defp get_credential_map(user) do
    initial_map = %{allowed_credentials: [], key_ids: []}

    for key <- user.keys, reduce: initial_map do
      result ->
        result
        |> Map.update!(:allowed_credentials, &[{key.key_id, key.public_key} | &1])
        |> Map.update!(:key_ids, &[Base.encode64(key.key_id, padding: false) | &1])
    end
  end
end
