defmodule WebauthnComponents.SupportComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.SupportComponent

  @id "support-component"

  setup do
    html =
      SupportComponent
      |> render_component(%{id: @id})
      |> Floki.parse_fragment!()

    %{html: html}
  end

  describe "render/1" do
    test "returns hidden element with id and phx hook", %{html: html} do
      node = Floki.get_by_id(html, @id)
      assert ["SupportHook"] = Floki.attribute(node, "phx-hook")
      assert [_target] = Floki.attribute(node, "phx-target")
      assert ["hidden"] = Floki.attribute(node, "class")
    end
  end

  describe "handle_event/3" do
    test "accepts passkeys-supported event", %{socket: socket} do
      params = %{"supported" => true}
      assert response = SupportComponent.handle_event("passkeys-supported", params, socket)
      assert {:noreply, socket} = response
      assert %Phoenix.LiveView.Socket{} = socket
      assert_receive {:passkeys_supported, true}
    end

    test "sends invalid events to the parent view", %{socket: socket} do
      event = "invalid-event"
      params = %{"invalid_key" => "invalid value"}
      assert {:noreply, _socket} = SupportComponent.handle_event(event, params, socket)
      assert_receive {:invalid_event, ^event, ^params}
    end
  end
end
