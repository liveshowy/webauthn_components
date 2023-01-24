defmodule WebauthnComponents.SupportComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.SupportComponent

  @id "support-component"

  setup do
    {:ok, view, html} = live_isolated_component(SupportComponent, %{id: @id})
    element = element(view, "##{@id}")
    %{view: view, html: html, element: element}
  end

  describe "render/1" do
    test "returns element with id and phx hook", %{html: html} do
      assert html =~ "id=\"#{@id}\""
      assert html =~ "phx-hook=\"SupportHook\""
    end
  end

  describe "handle_event/3 - passkeys-supported" do
    test "accepts valid payload", %{element: element, view: view} do
      assert render_hook(element, "passkeys-supported", %{"supported" => true})
      assert_handle_info(view, {:passkeys_supported, true})
    end
  end

  describe "handle_event/3 - fallback" do
    test "sends invalid events to the parent view", %{element: element, view: view} do
      assert render_hook(element, "invalid", %{"invalid_key" => "invalid value"})
      assert_handle_info(view, {:invalid_event, "invalid", %{"invalid_key" => "invalid value"}})
    end
  end
end
