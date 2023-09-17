defmodule <%= inspect @web_pascal_case %>.AuthenticationLiveTest do
  @moduledoc false
  use <%= inspect @web_pascal_case %>.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.Identity.User
  alias <%= inspect @app_pascal_case %>.IdentityFixtures
  alias <%= inspect @app_pascal_case %>.Repo

  defp route, do: ~p"/sign-in"

  describe "mount & render" do
    test "includes expected elements", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, route())

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
    end
  end

  describe "handle_event: update-form" do
    test "results in updated form", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      attrs = %{email: IdentityFixtures.unique_email()}

      assert view
             |> element("form[phx-change='update-form']")
             |> render_change(attrs)

      assert has_element?(view, "input[type='email'][name='email'][value='#{attrs.email}']")
    end
  end

  describe "handle_info: passkeys_supported" do
    test "renders flash when not supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      Process.send(view.pid, {:passkeys_supported, false}, [])

      assert view
             |> has_element?("#flash", "Passkeys are not supported in this browser.")
    end

    test "does not render flash when supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      Process.send(view.pid, {:passkeys_supported, true}, [])

      refute view
             |> has_element?("#flash", "Passkeys are not supported in this browser.")
    end
  end

  # Since some events are handled internally by the RegistrationComponent,
  # we need to mock the messages sent from the component to the LiveView.

  describe "handle_info: registration_successful" do
    test "results in a new user token", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      email = IdentityFixtures.unique_email()

      assert render_change(view, "update-form", %{email: email})

      key = IdentityFixtures.user_key_attrs()

      msg = {:registration_successful, key: key}
      send(view.pid, msg)
      render(view)

      assert {:ok, %User{} = user} = Identity.get_by_key_id(key.key_id)
      %User{tokens: [token | _other_tokens]} = Repo.preload(user, [:tokens])
      token_value = Base.encode64(token.value, padding: false)

      token_form_selector = "form#token-form[method='post'][action='/session']"
      assert has_element?(view, token_form_selector)
      assert has_element?(view, "form#token-form input[name='value'][value='#{token_value}']")
    end
  end

  describe "handle_info: find_credentials" do
  end

  describe "handle_info: authentication_successful" do
  end

  describe "handle_info: authentication_failure" do
  end
end
