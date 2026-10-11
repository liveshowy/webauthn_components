defmodule WebauthnComponents.AuthenticationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.AuthenticationComponent
  alias WebauthnComponents.PublicKeyCredentialRequestOptions
  alias WebauthnComponents.AllowCredential
  alias WebauthnComponents.PublicKeyCredential
  alias WebauthnComponents.AuthenticatorAssertionResponse
  alias WebauthnComponents.FindUser

  @id "test-component"

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
        allow_credentials: [%AllowCredential{id: <<0, 1, 2>>}]
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
    test "renders the passkey autofill input when mediation is conditional" do
      html = render_component_html(mediation: "conditional")

      assert html =~ ~s{autocomplete="webauthn"}
      assert html =~ ~s{phx-hook="AuthenticationHook"}
    end

    test "omits the passkey autofill input when mediation is not conditional" do
      html = render_component_html(mediation: "optional")

      refute html =~ ~s{autocomplete="webauthn"}
    end
  end

  describe "update/2" do
    setup %{socket: socket} do
      socket =
        assign(socket,
          id: @id,
          public_key_credential_request_options: %PublicKeyCredentialRequestOptions{}
        )

      %{
        socket: socket
      }
    end

    test "assigns custom values", %{socket: socket} do
      assert {:ok, socket} =
               AuthenticationComponent.update(%{disabled: true, class: "test"}, socket)

      assert %{disabled: true, class: "test"} = socket.assigns
    end

    test "processes conditional mediation", %{socket: socket} do
      assert {:ok, socket} = AuthenticationComponent.update(%{mediation: "conditional"}, socket)

      %{private: %{live_temp: %{push_events: push_events}}} = socket
      assert [["get-credential", event_params]] = push_events

      assert %{
               id: @id,
               mediation: "conditional",
               publicKey: public_key
             } = event_params

      assert %PublicKeyCredentialRequestOptions{} = public_key
    end

    test "processes valid credentials", %{socket: socket} do
      challenge = build_challenge()
      credential = build_credential()
      assertion = build_assertion(challenge, credential)

      socket =
        assign(socket, %{
          challenge: challenge,
          credential: build_public_key_credential(credential, assertion, "user_handle")
        })

      assert {:ok, socket} =
               AuthenticationComponent.update(
                 %{credentials: [credential_pair(credential)]},
                 socket
               )

      assert_receive {id, auth_data}
      assert id == credential.id
      assert is_struct(auth_data, Wax.AuthenticatorData)
      assert %{challenge: nil, credential: nil} = socket.assigns
    end

    test "sends error with invalid credentials", %{socket: socket} do
      socket =
        assign(socket, %{
          challenge: build_challenge(),
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

      assert {:ok, socket} = AuthenticationComponent.update(%{credentials: []}, socket)

      assert_receive %Wax.InvalidClientDataError{reason: :credential_id_mismatch}
      assert %{challenge: nil, credential: nil} = socket.assigns
    end

    test "sends error when no pending credential exists", %{socket: socket} do
      assert {:ok, ^socket} = AuthenticationComponent.update(%{credentials: []}, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
    end
  end

  describe "handle_event/3" do
    test "processes an `authenticate` event", %{socket: socket} do
      socket =
        assign(socket,
          id: @id,
          mediation: "optional",
          public_key_credential_request_options: %PublicKeyCredentialRequestOptions{}
        )

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("authenticate", %{}, socket)

      assert %{challenge: %Wax.Challenge{}} = socket.assigns

      %{private: %{live_temp: %{push_events: push_events}}} = socket
      assert [["get-credential", event_params]] = push_events

      assert %{
               id: @id,
               mediation: "optional",
               publicKey: public_key
             } = event_params

      assert %PublicKeyCredentialRequestOptions{} = public_key
    end

    test "processes a `credential` event", %{socket: socket} do
      challenge = build_challenge()
      credential = build_credential()
      assertion = build_assertion(challenge, credential)
      params = build_credential_params(credential, assertion, "user_handle")

      socket = assign(socket, challenge: challenge)

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", params, socket)

      assert_receive %FindUser{user_handle: "user_handle"}

      assert %{credential: %PublicKeyCredential{id: id, type: "public-key"}} = socket.assigns
      assert id == credential.id
    end

    test "sends error when challenge is missing", %{socket: socket} do
      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", %{}, socket)

      assert_receive %Wax.ExpiredChallengeError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error with missing credential fields", %{socket: socket} do
      socket = assign(socket, challenge: build_challenge())

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", %{}, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error with malformed base64", %{socket: socket} do
      challenge = build_challenge()
      credential = build_credential()
      assertion = build_assertion(challenge, credential)

      params =
        build_credential_params(credential, assertion, "user_handle")
        |> put_in(["id"], "not*valid*base64")

      socket = assign(socket, challenge: challenge)

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", params, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error when userHandle is missing", %{socket: socket} do
      challenge = build_challenge()
      credential = build_credential()
      assertion = build_assertion(challenge, credential)

      params =
        build_credential_params(credential, assertion, "user_handle")
        |> put_in(["response", "userHandle"], nil)

      socket = assign(socket, challenge: challenge)

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", params, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
      refute_received %FindUser{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error with a non-map payload", %{socket: socket} do
      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", "invalid", socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "processes an `error` event", %{socket: socket} do
      payload = %{"message" => "Something went wrong"}

      assert {:noreply, _socket} =
               AuthenticationComponent.handle_event("error", payload, socket)

      assert_receive {:error, ^payload}
    end
  end

  describe "authentication flow" do
    test "authenticates a credential from challenge to verification", %{socket: socket} do
      socket =
        assign(socket,
          id: @id,
          mediation: "optional",
          public_key_credential_request_options: %PublicKeyCredentialRequestOptions{}
        )

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("authenticate", %{}, socket)

      challenge = socket.assigns.challenge
      credential = build_credential()
      assertion = build_assertion(challenge, credential)
      params = build_credential_params(credential, assertion, "user_handle")

      assert {:noreply, socket} =
               AuthenticationComponent.handle_event("credential", params, socket)

      assert_receive %FindUser{user_handle: "user_handle"}

      assert {:ok, socket} =
               AuthenticationComponent.update(
                 %{credentials: [credential_pair(credential)]},
                 socket
               )

      assert_receive {id, auth_data}
      assert id == credential.id
      assert is_struct(auth_data, Wax.AuthenticatorData)
      assert %{challenge: nil, credential: nil} = socket.assigns
    end
  end

  defp build_challenge do
    Wax.new_authentication_challenge(
      allow_credentials: [],
      origin: TestEndpoint.url(),
      rp_id: :auto,
      user_verification: :required
    )
  end

  defp build_credential do
    {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256r1)
    <<4, x::binary-size(32), y::binary-size(32)>> = public_key

    %{
      id: :crypto.strong_rand_bytes(32),
      private_key: private_key,
      public_key: %{1 => 2, 3 => -7, -1 => 1, -2 => x, -3 => y}
    }
  end

  defp credential_pair(credential) do
    %{id: credential.id, public_key: credential.public_key}
  end

  defp build_assertion(%Wax.Challenge{} = challenge, credential) do
    authenticator_data =
      :crypto.hash(:sha256, challenge.rp_id) <>
        <<0b00000101>> <> <<0::unsigned-big-integer-size(32)>>

    client_data_json =
      Jason.encode!(%{
        "type" => "webauthn.get",
        "challenge" => Base.url_encode64(challenge.bytes, padding: false),
        "origin" => challenge.origin,
        "clientExtensions" => %{}
      })

    signature =
      :crypto.sign(
        :ecdsa,
        :sha256,
        authenticator_data <> :crypto.hash(:sha256, client_data_json),
        [credential.private_key, :secp256r1]
      )

    %{
      authenticator_data: authenticator_data,
      client_data_json: client_data_json,
      signature: signature
    }
  end

  defp build_credential_params(credential, assertion, user_handle) do
    %{
      "id" => Base.url_encode64(credential.id, padding: false),
      "type" => "public-key",
      "authenticatorAttachment" => "platform",
      "response" => %{
        "userHandle" => Base.url_encode64(user_handle, padding: false),
        "authenticatorData" => Base.url_encode64(assertion.authenticator_data, padding: false),
        "clientDataJSON" => Base.url_encode64(assertion.client_data_json, padding: false),
        "signature" => Base.url_encode64(assertion.signature, padding: false)
      }
    }
  end

  defp build_public_key_credential(credential, assertion, user_handle) do
    %PublicKeyCredential{
      id: credential.id,
      type: "public-key",
      authenticator_attachment: "platform",
      response: %AuthenticatorAssertionResponse{
        user_handle: user_handle,
        authenticator_data: assertion.authenticator_data,
        client_data_json: assertion.client_data_json,
        signature: assertion.signature
      }
    }
  end

  defp render_component_html(overrides) do
    assigns =
      Map.merge(
        %{
          id: @id,
          disabled: false,
          class: nil,
          rest: %{},
          mediation: "optional",
          myself: nil,
          inner_block: [],
          public_key_credential_request_options: %PublicKeyCredentialRequestOptions{}
        },
        Map.new(overrides)
      )

    AuthenticationComponent.render(assigns) |> rendered_to_string()
  end
end
