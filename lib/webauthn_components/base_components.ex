defmodule WebauthnComponents.BaseComponents do
  @moduledoc false
  use Phoenix.Component

  attr :id, :string
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false

  attr :class, :string,
    default: """
    px-2 py-1 border border-gray-300 dark:border-gray-600 hover:border-transparent bg-gray-200 hover:bg-blue-600 hover:text-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 transition rounded text-base shadow-sm flex gap-2 items-center hover:-translate-y-px hover:shadow-md
    """

  attr :rest, :global

  slot :inner_block, required: true

  @doc false
  def button(assigns) do
    ~H"""
    <button id={@id} type={@type} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
