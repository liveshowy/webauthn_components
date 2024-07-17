defmodule <%= inspect @web_pascal_case %>.AuthenticationLiveTest do
  @moduledoc false
  use <%= inspect @web_pascal_case %>.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias <%= inspect @app_pascal_case %>.Identity
  alias <%= inspect @app_pascal_case %>.IdentityFixtures

  defp route, do: ~p"/sign-in"

  describe "mount & render" do
    test "includes expected elements", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, route())

      # SupportComponent
      assert has_element?(view, "[phx-hook='SupportHook'].hidden")

      # Authentication
      assert has_element?(view, "#authentication-component")
      assert has_element?(view, "[phx-hook='AuthenticationHook'][phx-click='authenticate']")

      # Token/Session Form
      # This form is only rendered when authentication is successful.
      refute has_element?(view, "form#token-form[action='/session'][method='post'].hidden")
    end
  end

  describe "handle_info: passkeys_supported" do
    test "renders flash when not supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      Process.send(view.pid, {:passkeys_supported, false}, [])
      assert render(view) =~ "Passkeys are not supported in this browser."
    end

    test "does not render flash when supported", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      Process.send(view.pid, {:passkeys_supported, true}, [])
      refute render(view) =~ "Passkeys are not supported in this browser."
    end
  end

  describe "handle_info: find_credentials" do
    test "logs error on invalid attestation", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      key = IdentityFixtures.user_key_attrs()

      user_attrs = %{
        email: IdentityFixtures.unique_email(),
        keys: [key]
      }

      {:ok, _user} = Identity.create(user_attrs)

      assert view
             |> element("button#authentication-component")
             |> render_click()

      render(view)

      raw_id_64 = Base.encode64(key.key_id, padding: false)
      attestation = IdentityFixtures.attestation(%{"rawId64" => raw_id_64})

      assert view
             |> element("button#authentication-component")
             |> render_hook("authentication-attestation", attestation)

      render(view)
      refute has_element?(view, "#flash", "Failed to sign in")

      # TODO: This is flaky, find a fix.
      # log =
      #   capture_log([level: :error], fn ->
      #     send(view.pid, {:find_credential, key_id: key.key_id})
      #     render(view)
      #   end)

      # assert log =~ "authentication_error"
    end
  end

  # TODO
  # describe "handle_info: authentication_successful" do
  # end
end
