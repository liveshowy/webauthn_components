defmodule <%= inspect @web_pascal_case %>.PasskeyComponents do
  @moduledoc """
  Components for navigating the application.
  """
  use Phoenix.Component
  use <%= inspect @web_pascal_case %>, :verified_routes
  import <%= inspect @web_pascal_case %>.CoreComponents
  alias Phoenix.LiveView.JS

  embed_templates "/passkeys/*"

  def guidance(assigns)

  attr :form, Phoenix.HTML.Form, required: true, doc: "Form used to create a session upon successful registration or authentication."

  def token_form(assigns)
end
