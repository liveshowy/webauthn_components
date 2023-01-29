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
    <button id={@id} type={@type} class="px-2 py-1 border border-gray-300 hover:border-transparent bg-gray-200 hover:bg-blue-200 focus:bg-blue-300 text-gray-900 transition rounded text-base shadow-sm flex gap-2 items-center hover:-translate-y-px hover:shadow-md" {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
