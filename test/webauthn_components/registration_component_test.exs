defmodule WebauthnComponents.RegistrationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.PublicKeyCredentialCreationOptions
  alias WebauthnComponents.RelyingParty
  alias WebauthnComponents.User

  @id "test-component"

  describe "mount/1" do
    test "sets default assigns", %{socket: socket} do
      assert {:ok, socket} = RegistrationComponent.mount(socket)

      assert %{
               disabled: disabled,
               class: _class,
               rest: rest,
               trusted_attestation_types: trusted_attestation_types
             } = socket.assigns

      assert is_boolean(disabled)
      assert is_map(rest)
      assert Enum.all?(trusted_attestation_types, &is_atom/1)
    end

    test "accepts custom assigns", %{socket: socket} do
      socket =
        assign(socket,
          class: "test",
          disabled: true,
          rest: %{title: "hi"},
          trusted_attestation_types: [:none]
        )

      assert {:ok, socket} = RegistrationComponent.mount(socket)

      assert %{
               disabled: true,
               class: "test",
               rest: %{title: "hi"},
               trusted_attestation_types: [:none]
             } = socket.assigns
    end
  end

  describe "render/1" do
    test "is successful with required assigns" do
      assigns = %{
        public_key_options: nil
      }

      heex = ~H"""
      <.live_component
        id="test-component"
        module={RegistrationComponent}
        public_key_options={@public_key_options}
      >
        Sign Up
      </.live_component>
      """

      assert %Phoenix.LiveView.Rendered{} = heex
    end
  end

  describe "handle_event/3" do
    test "processes a `register` event", %{socket: socket} do
      socket = assign_public_key_options(socket)

      assert {:noreply, socket} = RegistrationComponent.handle_event("register", %{}, socket)

      assert %{challenge: %Wax.Challenge{} = challenge} = socket.assigns

      %{private: %{live_temp: %{push_events: push_events}}} = socket
      assert [["registration-challenge", event_params]] = push_events

      assert %{
               id: @id,
               publicKey: %PublicKeyCredentialCreationOptions{challenge: public_key_challenge}
             } = event_params

      assert public_key_challenge == challenge.bytes
    end

    test "processes a valid `credential` event", %{socket: socket} do
      socket = assign_challenge(socket)
      attestation = build_attestation(socket.assigns.challenge)
      credential_id = attestation.credential_id
      params = build_credential_params(attestation)

      assert {:noreply, socket} =
               RegistrationComponent.handle_event("credential", params, socket)

      assert_receive %Wax.AuthenticatorData{
        attested_credential_data: %{credential_id: ^credential_id}
      }

      assert %{challenge: nil} = socket.assigns
    end

    test "sends error when challenge is missing", %{socket: socket} do
      assert {:noreply, socket} =
               RegistrationComponent.handle_event("credential", %{}, socket)

      assert_receive %Wax.ExpiredChallengeError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error with missing credential fields", %{socket: socket} do
      socket = assign_challenge(socket)

      assert {:noreply, socket} =
               RegistrationComponent.handle_event("credential", %{}, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
      assert %{challenge: nil} = socket.assigns
    end

    test "sends error with invalid CBOR", %{socket: socket} do
      socket = assign_challenge(socket)

      client_data_json =
        %{
          "challenge" => Base.url_encode64(socket.assigns.challenge.bytes, padding: false),
          "clientExtensions" => %{},
          "hashAlgorithm" => "SHA-256",
          "origin" => TestEndpoint.url(),
          "type" => "webauthn.create"
        }
        |> JSON.encode!()
        |> Base.url_encode64(padding: false)

      credential = %{
        "response" => %{
          "attestationObject" => Base.url_encode64("{}", padding: false),
          "clientDataJSON" => client_data_json
        }
      }

      assert {:noreply, _socket} =
               RegistrationComponent.handle_event("credential", credential, socket)

      # Expect registration to fail due to the contrived credential
      assert_receive %Wax.InvalidCBORError{}
    end

    test "processes an `error` event", %{socket: socket} do
      payload = %{"message" => "Something went wrong"}

      assert {:noreply, _socket} = RegistrationComponent.handle_event("error", payload, socket)

      assert_receive {:error, ^payload}
    end
  end

  describe "registration flow" do
    test "registers a credential from challenge to verification", %{socket: socket} do
      socket = assign_public_key_options(socket)

      assert {:noreply, socket} = RegistrationComponent.handle_event("register", %{}, socket)

      attestation = build_attestation(socket.assigns.challenge)
      credential_id = attestation.credential_id
      params = build_credential_params(attestation)

      assert {:noreply, socket} =
               RegistrationComponent.handle_event("credential", params, socket)

      assert_receive %Wax.AuthenticatorData{
        attested_credential_data: %{credential_id: ^credential_id}
      }

      assert %{challenge: nil} = socket.assigns
    end
  end

  defp build_public_key_options do
    %PublicKeyCredentialCreationOptions{
      rp: %RelyingParty{name: "Test"},
      user: %User{id: "1234", name: "tester", display_name: "Tester"}
    }
  end

  defp assign_public_key_options(socket) do
    assign(socket,
      id: @id,
      public_key_options: build_public_key_options(),
      trusted_attestation_types: [:none, :basic]
    )
  end

  defp assign_challenge(socket) do
    socket = assign_public_key_options(socket)

    assert {:noreply, socket} = RegistrationComponent.handle_event("register", %{}, socket)
    socket
  end

  defp build_attestation(%Wax.Challenge{} = challenge) do
    {public_key, _private_key} = :crypto.generate_key(:ecdh, :secp256r1)
    <<4, x::binary-size(32), y::binary-size(32)>> = public_key

    cose_key = %{1 => 2, 3 => -7, -1 => 1, -2 => x, -3 => y}
    credential_id = :crypto.strong_rand_bytes(32)

    auth_data =
      :crypto.hash(:sha256, challenge.rp_id) <>
        <<0b01000101>> <>
        <<0::unsigned-big-integer-size(32)>> <>
        <<0::128>> <>
        <<byte_size(credential_id)::unsigned-big-integer-size(16)>> <>
        credential_id <>
        CBOR.encode(cose_key)

    attestation_object =
      CBOR.encode(%{"fmt" => "none", "attStmt" => %{}, "authData" => auth_data})

    client_data_json =
      Jason.encode!(%{
        "type" => "webauthn.create",
        "challenge" => Base.url_encode64(challenge.bytes, padding: false),
        "origin" => challenge.origin,
        "clientExtensions" => %{}
      })

    %{
      attestation_object: attestation_object,
      client_data_json: client_data_json,
      credential_id: credential_id
    }
  end

  defp build_credential_params(attestation) do
    %{
      "id" => Base.url_encode64(attestation.credential_id, padding: false),
      "response" => %{
        "attestationObject" => Base.url_encode64(attestation.attestation_object, padding: false),
        "clientDataJSON" => Base.url_encode64(attestation.client_data_json, padding: false)
      }
    }
  end
end
