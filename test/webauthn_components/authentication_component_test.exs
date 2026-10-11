defmodule WebauthnComponents.AuthenticationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.AuthenticationComponent
  alias WebauthnComponents.Config.PublicKeyCredentialRequestOptions
  alias WebauthnComponents.Config.PublicKeyCredential
  alias WebauthnComponents.Config.AuthenticatorAssertionResponse

  describe "mount/1" do
    test "sets default assigns", %{socket: socket} do
      assert {:ok, socket} = AuthenticationComponent.mount(socket)

      assert %{
               disabled: disabled,
               class: _class,
               rest: rest,
               mediation: mediation,
               public_key_credential_request_options: public_key_credential_request_options
             } = socket.assigns

      assert is_boolean(disabled)
      assert is_map(rest)
      assert is_binary(mediation)
      assert is_struct(public_key_credential_request_options, PublicKeyCredentialRequestOptions)
    end

    test "accepts custom assigns", %{socket: socket} do
      public_key_credential_request_options = %PublicKeyCredentialRequestOptions{
        allow_credentials: [{<<0, 1, 2>>, %{}}]
      }

      socket =
        assign(socket,
          class: "test",
          disabled: true,
          rest: %{title: "hi"},
          public_key_credential_request_options: public_key_credential_request_options
        )

      assert {:ok, socket} = AuthenticationComponent.mount(socket)

      assert %{
               class: "test",
               disabled: true,
               rest: %{title: "hi"},
               public_key_credential_request_options: ^public_key_credential_request_options
             } = socket.assigns
    end
  end

  describe "render/1" do
    test "is successful with required assigns" do
      assigns = %{}

      heex = ~H"""
      <.live_component
        id="test-component"
        module={AuthenticationComponent}
      >
        <span>Log in with a Passkey</span>
      </.live_component>
      """

      assert %Phoenix.LiveView.Rendered{} = heex
    end
  end

  describe "update/2" do
    setup %{socket: socket} do
      socket =
        assign(socket,
          id: "test_component",
          public_key_credential_request_options: %PublicKeyCredentialRequestOptions{}
        )

      %{
        socket: socket
      }
    end

    test "processes conditional mediation", %{socket: socket} do
      assert {:ok, socket} = AuthenticationComponent.update(%{mediation: "conditional"}, socket)
      # dbg(socket, structs: false)
      %{private: %{live_temp: %{push_events: push_events}}} = socket
      assert [["get-credential", event_params]] = push_events

      assert %{
               id: "test_component",
               mediation: "conditional",
               publicKey: public_key
             } = event_params

      assert %PublicKeyCredentialRequestOptions{} = public_key
    end

    test "processes credentials", %{socket: socket} do
      socket =
        assign(socket, %{
          challenge:
            Wax.new_authentication_challenge(
              allow_credentials: [],
              origin: TestEndpoint.url(),
              rp_id: :auto,
              user_verification: :required
            ),
          credential: %PublicKeyCredential{
            authenticator_attachment: "platform",
            id: :crypto.strong_rand_bytes(32),
            response: %AuthenticatorAssertionResponse{
              authenticator_data: "",
              client_data_json: "{}",
              signature: "",
              user_handle: ""
            },
            type: "public-key"
          }
        })

      assert {:ok, socket} =
               AuthenticationComponent.update(%{credentials: []}, socket)

      assert_receive {id, auth_data}
      assert is_binary(id)
      assert is_struct(auth_data, Wax.AuthenticatorData)
      assert %{challenge: nil, credential: nil} = socket.assigns
    end
  end

  describe "handle_event/3" do
    test "processes an `authenticate` event"
    test "processes an `credential` event"
  end
end
