defmodule <%= inspect @web_pascal_case %>.AuthenticationLiveTest do
  @moduledoc false
  use <%= inspect @web_pascal_case %>.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias <%= inspect @app_pascal_case %>.IdentityFixtures

  describe "mount & render" do
    test "includes expected elements", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, ~p"/sign-in")

      # SupportComponent
      assert has_element?(view, "[phx-hook='SupportHook'].hidden")

      # Passkey Form
      assert has_element?(view, "form[phx-change='update-form'][phx-submit]")

      # Registration
      assert has_element?(view, "form fieldset#fieldset-authentication")
      assert has_element?(view, "form input[type='email'][name='email']")
      assert has_element?(view, "[phx-hook='RegistrationHook'][phx-click='register']")

      # Authentication
      assert has_element?(view, "form fieldset#fieldset-registration")
      assert has_element?(view, "[phx-hook='AuthenticationHook'][phx-click='authenticate']")

      # Token/Session Form
      # This form is only rendered when registration or authentication is successful.
      refute has_element?(view, "form#token-form[action='/session'][method='post'].hidden")
      # assert has_element?(view, "form#token-form input[type='text'][name='value']")
      # assert has_element?(view, "form#token-form button[type='submit']")
    end
  end

  describe "handle_event: update-form" do
    test "results in updated form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")
      attrs = %{email: IdentityFixtures.unique_email()}

      assert view
             |> element("form[phx-change='update-form']")
             |> render_change(attrs)

      assert has_element?(view, "input[type='email'][name='email'][value='#{attrs.email}']")
    end
  end

  describe "handle_info: passkeys_supported" do
    test "renders flash when not supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")
      Process.send(view.pid, {:passkeys_supported, false}, [])

      assert view
             |> has_element?("#flash", "Passkeys are not supported in this browser.")
    end

    test "does not render flash when supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")
      Process.send(view.pid, {:passkeys_supported, true}, [])

      refute view
             |> has_element?("#flash", "Passkeys are not supported in this browser.")
    end
  end

  describe "handle_info: registration_successful" do
  end

  describe "handle_info: find_credentials" do
  end
end
