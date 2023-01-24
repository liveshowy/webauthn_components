defmodule WebauthnComponents.TokenComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.TokenComponent

  @id "token-component"

  setup do
    {:ok, view, html} = live_isolated_component(TokenComponent, %{id: @id})
    element = element(view, "##{@id}")
    %{view: view, html: html, element: element}
  end

  describe "render/1" do
    test "returns element with id and phx hook", %{html: html} do
      assert html =~ "id=\"#{@id}\""
      assert html =~ "phx-hook=\"TokenHook\""
    end
  end

  describe "handle_event/3 - token-exists" do
    test "accepts valid payload", %{element: element, view: view} do
      assert render_hook(element, "token-exists", %{"token" => "1234"})
      assert_handle_info(view, {:token_exists, token: "1234"})
    end
  end

  describe "handle_event/3 - token-stored" do
    test "accepts valid payload", %{element: element, view: view} do
      token = "123456"
      live_assign(view, :token, token)
      assert render_hook(element, "token-stored", %{"token" => token})
      assert_handle_info(view, {:token_stored, token: ^token})
    end
  end

  describe "handle_event/3 - token-cleared" do
    test "accepts valid payload", %{element: element, view: view} do
      assert render_hook(element, "token-cleared", %{"token" => nil})
      assert_handle_info(view, {:token_cleared})
    end
  end

  describe "handle_event/3 - error" do
    test "accepts valid payload", %{element: element, view: view} do
      error = %{
        "message" => "test message",
        "name" => "test name",
        "stack" => %{}
      }

      assert render_hook(element, "error", error)
      assert_handle_info(view, {:error, ^error})
    end
  end

  describe "handle_event/3 - fallback" do
    test "sends invalid event to parent view", %{element: element, view: view} do
      assert render_hook(element, "invalid", %{"invalid_key" => "invalid value"})
      assert_handle_info(view, {:invalid_event, "invalid", %{"invalid_key" => "invalid value"}})
    end
  end
end
