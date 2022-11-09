defmodule WebAuthnLiveComponent.Button do
  use Phoenix.Component

  attr :label, :string,
    default: "Sign in a Passkey",
    doc: "Text to be rendered inside the button, visible to the user"

  attr :class, :string, default: "px-4 p-2 bg-blue-500 text-white rounded shadow-md"

  attr :rest, :global

  def render(assigns) do
    ~H"""
    <button class={@class} {@rest}>
      <%= @label %>
    </button>
    """
  end
end
