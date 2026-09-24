defmodule WebauthnComponents.SchemasTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias WebauthnComponents.Config.AuthenticatorSelection
  alias WebauthnComponents.Config.ExcludedCredential
  alias WebauthnComponents.Config.PubKeyCredParams
  alias WebauthnComponents.Config.PublicKeyOptions
  alias WebauthnComponents.Config.RelyingParty
  alias WebauthnComponents.Config.User

  @attestation ~w(none direct enterprise indirect)
  @attestation_formats ~w(packed tpm android-key android-safetynet fido-u2f apple none)
  @hints ~w(security-key client-device hybrid)

  describe "PublicKeyOptions" do
    test "missing keys raise an error" do
      assert_raise ArgumentError, fn -> struct!(PublicKeyOptions) end
    end

    test "can be built with only required fields" do
      options = %PublicKeyOptions{
        challenge: :crypto.strong_rand_bytes(32),
        rp: %RelyingParty{id: "example.com", name: "Example Org"},
        user: %User{id: Ecto.UUID.generate(), name: "example_user", display_name: "Example User"},
        pub_key_cred_params: %PubKeyCredParams{alg: -8}
      }

      assert is_integer(options.timeout)
      assert options.timeout > 0
      assert options.pub_key_cred_params.type == "public-key"
    end

    property "a PublicKeyOptions struct can be built with random values" do
      check all public_key_options <- public_key_options() do
        assert %PublicKeyOptions{} = public_key_options
      end
    end

    property "valid PublicKeyOptions can be encoded via JSON" do
      check all public_key_options <- public_key_options() do
        assert public_key_options |> JSON.encode!() |> JSON.decode!()
      end
    end

    property "valid PublicKeyOptions can be encoded via Jason" do
      check all public_key_options <- public_key_options() do
        assert public_key_options |> Jason.encode!() |> Jason.decode!()
      end
    end
  end

  defp public_key_options do
    gen all attestation <- member_of(@attestation),
            attestation_formats <- list_of(member_of(@attestation_formats)),
            authenticator_selection <- authenticator_selection(),
            challenge <- binary(min_length: 16, max_length: 64),
            exclude_credentials <- list_of(exclude_credentials()),
            extensions <-
              map_of(string(:alphanumeric, min_length: 4), string(:alphanumeric, min_length: 4),
                max_length: 10
              ),
            hints <- list_of(member_of(@hints)),
            pub_key_cred_params <- list_of(pub_key_cred_params(), min_length: 1),
            rp <- rp(),
            timeout <- integer(0..60_000),
            user <- user() do
      %PublicKeyOptions{
        attestation: attestation,
        attestation_formats: attestation_formats,
        authenticator_selection: authenticator_selection,
        challenge: challenge,
        exclude_credentials: exclude_credentials,
        extensions: extensions,
        hints: hints,
        pub_key_cred_params: pub_key_cred_params,
        rp: rp,
        timeout: timeout,
        user: user
      }
    end
  end

  defp authenticator_selection do
    gen all authenticator_attachment <- member_of(~w(platform cross-platform)),
            resident_key <- member_of(~w(discouraged preferred required)),
            user_verification <- member_of(~w(discouraged preferred required)) do
      %AuthenticatorSelection{
        authenticator_attachment: authenticator_attachment,
        resident_key: resident_key,
        user_verification: user_verification
      }
    end
  end

  defp exclude_credentials do
    gen all id <- string(:alphanumeric, min_length: 4),
            transports <- list_of(member_of(~w(ble hybrid internal nfc usb))),
            type <- string(:alphanumeric, min_length: 4) do
      %ExcludedCredential{id: id, transports: transports, type: type}
    end
  end

  defp pub_key_cred_params do
    gen all alg <- integer(),
            type <- string(:alphanumeric, min_length: 4) do
      %PubKeyCredParams{alg: alg, type: type}
    end
  end

  defp rp do
    gen all id <- string(:alphanumeric, min_length: 4),
            name <- string(:alphanumeric, min_length: 4) do
      %RelyingParty{id: id, name: name}
    end
  end

  defp user do
    gen all id <- string(:alphanumeric, min_length: 4),
            name <- string(:alphanumeric, min_length: 4),
            display_name <- string(:alphanumeric, min_length: 4) do
      %User{id: id, name: name, display_name: display_name}
    end
  end
end
