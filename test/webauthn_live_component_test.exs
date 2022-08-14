defmodule WebauthnLiveComponentTest do
  @moduledoc false
  use ComponentCase
  import Phoenix.LiveView.Helpers
  doctest WebAuthnLiveComponent

  test "socket assigns include a valid changeset on mount" do
    socket = %Phoenix.LiveView.Socket{}
    assert {:ok, component} = WebAuthnLiveComponent.mount(socket)
    changeset = component.assigns.changeset
    assert %Ecto.Changeset{} = changeset
    assert Enum.empty?(changeset.errors)
    assert changeset.valid?
  end

  test "a form is rendered" do
    live_component = live_component(WebAuthnLiveComponent, id: "test_form")
    assert %Phoenix.LiveView.Component{component: component, assigns: assigns} = live_component
    assert %Phoenix.LiveView.Rendered{} = component.render(assigns)
    assert render_component(WebAuthnLiveComponent, id: "test_form") =~ "username"
  end
end
