defmodule WebAuthnLiveComponent.Form do
  @moduledoc """
  A LiveComponent for passwordless authentication via WebAuthn.
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import Phoenix.LiveView.Helpers
  alias Ecto.Changeset

  # prop changeset, :struct
  # prop user, :map
  # prop params, :map
  # prop css_class, :css_class
  # prop register_label, :string
  # prop authenticate_label, :string

  def mount(socket) do
    {
      :ok,
      socket
      |> assign_new(:changeset, &build_changeset/1)
      |> assign_new(:id, fn -> "passwordless_auth" end)
      |> assign_new(:css_class, fn -> "grid gap-2 grid-cols-2" end)
      |> assign_new(:register_label, fn -> "Sign Up" end)
      |> assign_new(:authenticate_label, fn -> "Sign In" end)
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
          "phx-debounce": "500",
          class: "col-span-full",
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

  def handle_event("change", %{"auth" => %{"username" => username}}, socket) do
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

  def handle_event("register", _payload, %{assigns: %{changeset: changeset}} = socket) do
    %{changes: %{username: username}} = changeset

    new_changeset =
      %{params: %{username: username}}
      |> build_changeset()
      |> add_changeset_requirements()

    send(self(), {:register_user, username: username})

    {
      :noreply,
      socket
      |> assign(:changeset, new_changeset)
    }
  end

  def handle_event("authenticate", _payload, %{assigns: %{changeset: changeset}} = socket) do
    %{changes: %{username: username}} = changeset

    new_changeset =
      %{params: %{username: username}}
      |> build_changeset()
      |> add_changeset_requirements()

    send(self(), {:authenticate_user, username: username})

    {
      :noreply,
      socket
      |> assign(:changeset, new_changeset)
    }
  end
end
