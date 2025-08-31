defmodule WebauthnComponents.RegistrationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.WebauthnUser

  @app "Test App"
  @id "registration-component"

  setup do
    assigns = %{app: @app, id: @id}
    {:ok, view, _html} = live_isolated_component(RegistrationComponent, assigns)
    live_assign(view, app: assigns.app, id: assigns.id)
    element = element(view, "##{assigns.id}-platform")
    %{view: view, element: element, default_assigns: assigns}
  end

  describe "render/1" do
    test "returns element with id and phx hook", %{view: view} do
      assert has_element?(view, "##{@id}-platform[phx-hook='RegistrationHook']")
      assert has_element?(view, "##{@id}-cross-platform[phx-hook='RegistrationHook']")
    end
  end

  describe "update/2" do
    test "updates `disabled` assign", setup_attrs do
      %{default_assigns: default_assigns} = setup_attrs
      assigns = Map.merge(default_assigns, %{disabled: true})
      {:ok, view, _html} = live_isolated_component(RegistrationComponent, assigns)
      assert has_element?(view, "##{assigns.id}-platform[disabled]")
      assert has_element?(view, "##{assigns.id}-cross-platform[disabled]")
    end

    test "is not `disabled` by default", setup_attrs do
      %{default_assigns: assigns} = setup_attrs
      {:ok, view, _html} = live_isolated_component(RegistrationComponent, assigns)
      assert has_element?(view, "##{assigns.id}-platform")
      assert has_element?(view, "##{assigns.id}-cross-platform")
      refute has_element?(view, "##{assigns.id}-platform[disabled]")
      refute has_element?(view, "##{assigns.id}-cross-platform[disabled]")
    end
  end

  describe "handle_event/3 - register" do
    test "sends registration challenge to client", %{element: element, view: view} do
      webauthn_user = %WebauthnUser{
        id: :crypto.strong_rand_bytes(64),
        name: "testUser",
        display_name: "Test User"
      }

      live_assign(view, :webauthn_user, webauthn_user)
      clicked_element = render_click(element)
      assert clicked_element =~ "<button"
      assert clicked_element =~ "phx-click=\"register\""

      assert_push_event(view, "registration-challenge", %{
        "id" => "registration-component",
        "user" => ^webauthn_user,
        "authenticatorAttachment" => "platform"
      })
    end
  end

  describe "handle_event/3 - registration-attestation" do
    test "fails registration with invalid payload", %{element: element, view: view} do
      challenge = build(:registration_challenge)
      live_assign(view, :challenge, challenge)

      attestation_64 = Base.encode64(:crypto.strong_rand_bytes(64), padding: false)
      raw_id_64 = Base.encode64(:crypto.strong_rand_bytes(64), padding: false)
      client_data = []

      payload = %{
        "attestation64" => attestation_64,
        "clientData" => client_data,
        "rawId64" => raw_id_64,
        "type" => "public-key"
      }

      assert render_hook(element, "registration-attestation", payload)
      assert_handle_info(view, {:registration_failure, [message: message]})
      assert message =~ "Invalid client data"
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
