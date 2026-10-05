defmodule WebauthnComponents.RegistrationComponentTest do
  use ComponentCase, async: true
  alias WebauthnComponents.RegistrationComponent
  alias WebauthnComponents.Config.PublicKeyCredentialCreationOptions
  alias WebauthnComponents.Config.RelyingParty
  alias WebauthnComponents.Config.User

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
      public_key_options = %PublicKeyCredentialCreationOptions{
        rp: %RelyingParty{name: "Test"},
        user: %User{id: "1234", name: "tester", display_name: "Tester"}
      }

      trusted_attestation_types = [:none, :basic]

      socket =
        socket
        |> Map.put(:endpoint, TestEndpoint)
        |> assign(
          id: "test-component",
          public_key_options: public_key_options,
          trusted_attestation_types: trusted_attestation_types
        )

      assert {:noreply, socket} = RegistrationComponent.handle_event("register", %{}, socket)
      assert %{challenge: challenge} = socket.assigns
      assert %Wax.Challenge{} = challenge
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

    test "sends error with empty credential object", %{socket: socket} do
      socket = assign_challenge(socket)

      credential = %{}

      assert {:noreply, _socket} =
               RegistrationComponent.handle_event("credential", credential, socket)

      assert_receive %Wax.InvalidAuthenticatorDataError{}
    end
  end

  defp assign_challenge(socket) do
    public_key_options = %PublicKeyCredentialCreationOptions{
      rp: %RelyingParty{name: "Test"},
      user: %User{id: "1234", name: "tester", display_name: "Tester"}
    }

    trusted_attestation_types = [:none, :basic]

    socket =
      socket
      |> Map.put(:endpoint, TestEndpoint)
      |> assign(
        id: "test-component",
        public_key_options: public_key_options,
        trusted_attestation_types: trusted_attestation_types
      )

    assert {:noreply, socket} = RegistrationComponent.handle_event("register", %{}, socket)
    socket
  end
end
