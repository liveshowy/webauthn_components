defmodule WebauthnComponents.SchemasTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Ecto.Changeset
  alias WebauthnComponents.Schemas.PublicKeyOptions

  @attestation ~w(none direct enterprise indirect)
  @attestation_formats ~w(packed tpm android-key android-safetynet fido-u2f apple none)
  @hints ~w(security-key client-device hybrid)

  property "valid params for PublicKeyOptions return a valid changeset" do
    check all params <- public_key_options() do
      changeset = PublicKeyOptions.changeset(%PublicKeyOptions{}, params)

      assert %Changeset{valid?: true} = changeset
      assert options = Changeset.apply_action!(changeset, :validate)
      assert %PublicKeyOptions{} = options
    end
  end

  property "valid PublicKeyOptions can be encoded via JSON" do
    check all params <- public_key_options() do
      changeset = PublicKeyOptions.changeset(%PublicKeyOptions{}, params)
      assert options = Changeset.apply_action!(changeset, :validate)
      assert options |> JSON.encode!() |> JSON.decode!()
    end
  end

  property "valid PublicKeyOptions can be encoded via Jason" do
    check all params <- public_key_options() do
      changeset = PublicKeyOptions.changeset(%PublicKeyOptions{}, params)
      assert options = Changeset.apply_action!(changeset, :validate)
      assert options |> Jason.encode!() |> Jason.decode!()
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
            timeout <- integer(),
            user <- user() do
      %{
        "attestation" => attestation,
        "attestation_formats" => attestation_formats,
        "authenticator_selection" => authenticator_selection,
        "challenge" => challenge,
        "exclude_credentials" => exclude_credentials,
        "extensions" => extensions,
        "hints" => hints,
        "pub_key_cred_params" => pub_key_cred_params,
        "rp" => rp,
        "timeout" => timeout,
        "user" => user
      }
    end
  end

  defp authenticator_selection do
    gen all authenticator_attachment <- member_of(~w(platform cross-platform)),
            resident_key <- member_of(~w(discouraged preferred required)),
            user_verification <- member_of(~w(discouraged preferred required)) do
      %{
        "authenticator_attachment" => authenticator_attachment,
        "resident_key" => resident_key,
        "user_verification" => user_verification
      }
    end
  end

  defp exclude_credentials do
    gen all id <- string(:alphanumeric, min_length: 4),
            transports <- list_of(member_of(~w(ble hybrid internal nfc usb))),
            type <- string(:alphanumeric, min_length: 4) do
      %{
        "id" => id,
        "transports" => transports,
        "type" => type
      }
    end
  end

  defp pub_key_cred_params do
    gen all alg <- integer(),
            type <- string(:alphanumeric, min_length: 4) do
      %{
        "alg" => alg,
        "type" => type
      }
    end
  end

  defp rp do
    gen all id <- string(:alphanumeric, min_length: 4),
            name <- string(:alphanumeric, min_length: 4) do
      %{
        "id" => id,
        "name" => name
      }
    end
  end

  defp user do
    gen all id <- string(:alphanumeric, min_length: 4),
            name <- string(:alphanumeric, min_length: 4),
            display_name <- string(:alphanumeric, min_length: 4) do
      %{
        "id" => id,
        "name" => name,
        "display_name" => display_name
      }
    end
  end
end
