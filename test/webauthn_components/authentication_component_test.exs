defmodule WebauthnComponents.AuthenticationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.AuthenticationComponent

  @id "authentication-component"

  setup do
    {:ok, view, html} = live_isolated_component(AuthenticationComponent, %{id: @id})
    element = element(view, "##{@id}")
    live_assign(view, :app, :demo)
    %{view: view, html: html, element: element}
  end

  describe "render/1" do
    test "returns element with id and phx hook", %{html: html} do
      assert html =~ "id=\"#{@id}\""
      assert html =~ "phx-hook=\"AuthenticationHook\""
    end
  end

  describe "handle_event/3 - authenticate" do
    test "sends authentication challenge to client", %{element: element, view: view} do
      clicked_element = render_click(element)
      assert clicked_element =~ "<button"
      assert clicked_element =~ "phx-click=\"authenticate\""

      assert_push_event(view, "authentication-challenge", %{
        id: "authentication-component"
      })
    end
  end

  describe "handle_event/3 - authentication-attestation" do
    # TODO
  end
end
