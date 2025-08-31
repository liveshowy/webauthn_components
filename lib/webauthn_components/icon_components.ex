defmodule WebauthnComponents.IconComponents do
  @moduledoc false
  use Phoenix.Component

  attr :type, :atom, required: true, values: [:key, :usb]

  def icon(assigns) do
    ~H"""
    <.icon_key :if={@type == :key} />
    <.icon_usb :if={@type == :usb} />
    """
  end

  @doc false
  def icon_key(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-full h-full min-w-4 min-h-4"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M15.75 5.25a3 3 0 013 3m3 0a6 6 0 01-7.029 5.912c-.563-.097-1.159.026-1.563.43L10.5 17.25H8.25v2.25H6v2.25H2.25v-2.818c0-.597.237-1.17.659-1.591l6.499-6.499c.404-.404.527-1 .43-1.563A6 6 0 1121.75 8.25z"
      />
    </svg>
    """
  end

  @doc false
  def icon_usb(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="currentColor"
      viewBox="0 0 24 24"
      stroke="currentColor"
      class="w-full h-full min-w-4 min-h-4"
    >
      <path d="M 23.5,12 L 21,10 L 21,11 L 8,11 L 10.5,6.5 C 10.75,6 11.125,5.5 11.5,5.5 C 12.75,5.5 13.25,5.5 13.5,5.5 C 13.75,7 14.5,8 15.5,8 C 16.75,8 17.5,7 17.5,5.5 C 17.5,4 16.75,3 15.5,3 C 14.5,3 13.75,4 13.5,5.5 L 11.5,5.5 C 11,5.5 10.25,6.25 10,6.75 L 7,11 L 5,11 C 4.75,9 3.5,7.5 2,7.5 C 0.75,7.5 0,9.25 0,12 C 0,14.75 0.75,16.5 2,16.5 C 3.5,16.5 4.75,15 5,13 L 7,13 L 10,17.25 C 10.25,17.75 11,18.5 11.5,18.5 L 13.5,18.5 L 13.5,20 L 16,20 L 16,16 L 13.5,16 L 13.5,17.5 L 11.5,17.5 C 11.125,17.5 10.75,17 10.5,16.5 L 8,13 L 21,13 L 21,14 L 23.5,12 z" />
    </svg>
    """
  end

  @doc false
  def icon_info_circle(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-full h-full"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
      />
    </svg>
    """
  end
end
