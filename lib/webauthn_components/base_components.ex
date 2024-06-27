defmodule WebauthnComponents.BaseComponents do
  @moduledoc false
  use Phoenix.Component

  attr :id, :string
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false

  attr :rest, :global

  slot :inner_block, required: true

  @doc false
  def button(assigns) do
    ~H"""
    <button id={@id} type={@type} {@rest} {if @disabled, do: %{disabled: true}, else: %{}}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
