defmodule WebauthnComponents.TokenComponent do
  @moduledoc """
  A LiveComponent for handling session tokens.

  `TokenComponent` manages the client-side session token, allowing the parent LiveView to do the following:

  - Redirect when a user is already signed in.
  - Store a new token upon registration or authentication.
  - Clear a token upon sign-out.

  See [USAGE.md](./USAGE.md) for example code.

  ## Assigns

  - `@id` (Optional) An HTML element ID.
  - `@token`: A Base64-encoded session token to be stored in the client.

  The parent LiveView may use [`Phoenix.LiveView.send_update/3`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#send_update/3) to set or clear a token in the client.

  ### Clear a Token

  ```elixir
  send_update(TokenComponent, id: "token-component", token: :clear)
  ```

  ### Store a Token

  ```elixir
  send_update(TokenComponent, id: "token-component", token: base64_encoded_token)
  ```

  ## Events

  The following events are handled internally by `TokenComponent`:

  - `"token-exists"`: Sent by the client when `sessionStorage` contains a `userToken`.
  - `"token-stored"`: Sent by the client when a token has been stored in `sessionStorage`.
  - `"token-cleared"`: Sent by the client when a token has been cleared frmo `sessionStorage`.
  - `"error"`: Sent by the client when an error occurs.

  ## Messages

  - `{:token_exists, token: token}`
    - `:token` is a Base64-encoded token found by the client.
    - The parent LiveView may use this token to authenticate users.
  - `{:token_stored, token: token}`
    - `:token` is a Base64-encoded token stored by the client.
    - The parent LiveView may compare the returned token against the token sent to the component to ensure there has been no tampering.
  - `{:token_cleared}`
    - A token has been cleared from the client.
  - `{:error, payload}`
    - `payload` contains the `message`, `name`, and `stack` returned by the browser upon timeout or other client-side errors.
  """
  use Phoenix.LiveComponent

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:id, fn -> "token-component" end)
      |> assign_new(:token, fn -> nil end)
    }
  end

  @doc """
  Stores or clears a session token.

  When a `:token` assign is received, this function will either clear or store the user's token.

  - Assign `token: :clear` to remove a user's token.
  - Assign a binary token (typically a base64-encoded crypto hash) to persist a user's token to the browser's `sessionStorage`.
  - Invalid token assigns will be logged and the socket will be returned unchanged.
  """
  def update(%{id: id, token: token} = _assigns, socket) do
    cond do
      token == :clear ->
        {
          :ok,
          socket
          |> push_event("clear-token", %{id: id, token: token})
        }

      is_binary(token) ->
        {
          :ok,
          socket
          |> assign(:token, token)
          |> push_event("store-token", %{id: id, token: token})
        }

      true ->
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
    <span id={@id} phx-hook="TokenHook" phx-target={@myself} class="hidden"></span>
    """
  end

  def handle_event("token-exists", %{"token" => token}, socket) when is_binary(token) do
    send(self(), {:token_exists, token: token})
    {:noreply, socket}
  end

  def handle_event("token-stored", %{"token" => client_token}, socket) do
    %{token: server_token} = socket.assigns

    if client_token == server_token do
      send(self(), {:token_stored, token: client_token})
    else
      send(self(), {
        :invalid_token_returned,
        server_token: server_token, client_token: client_token
      })
    end

    {:noreply, socket}
  end

  def handle_event("token-cleared", %{"token" => nil}, socket) do
    send(self(), {:token_cleared})
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
