defmodule WebauthnComponents.Config.PublicKeyOptions do
  @moduledoc """
  Struct representing options for registering a new credential.

  The struct is defined as an Ecto embedded schema to document the shape and provide guidance during implementation. The field keys are converted to camelCase when encoded as JSON.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
  - https://w3c.github.io/webauthn/#dictionary-makecredentialoptions
  """
  alias WebauthnComponents.Config.AuthenticatorSelection
  alias WebauthnComponents.Config.ExcludedCredential
  alias WebauthnComponents.Config.PubKeyCredParams
  alias WebauthnComponents.Config.User
  alias WebauthnComponents.Config.RelyingParty

  @type t :: %__MODULE__{
          attestation: :none | :direct | :enterprise | :indirect,
          attestation_formats: [String.t()],
          authenticator_selection: AuthenticatorSelection.t(),
          challenge: binary(),
          exclude_credentials: [ExcludedCredential.t()],
          extensions: map(),
          hints: [String.t()],
          pub_key_cred_params: [PubKeyCredParams.t()],
          rp: RelyingParty.t(),
          timeout: pos_integer(),
          user: User.t()
        }

  @enforce_keys [
    :challenge,
    :pub_key_cred_params,
    :rp,
    :user
  ]

  defstruct [
    :attestation_formats,
    :authenticator_selection,
    :challenge,
    :exclude_credentials,
    :extensions,
    :hints,
    :pub_key_cred_params,
    :rp,
    :user,
    attestation: :none,
    timeout: :timer.seconds(60)
  ]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:challenge, &Base.encode64(&1, padding: false))
      |> Map.put(:attestationFormats, struct.attestation_formats)
      |> Map.put(:attestationSelection, struct.authenticator_selection)
      |> Map.put(:excludeCredentials, struct.exclude_credentials)
      |> Map.put(:pubKeyCredParams, struct.pub_key_cred_params)
      |> Map.drop([
        :attestation_formats,
        :authenticator_selection,
        :exclude_credentials,
        :pub_key_cred_params
      ])
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:challenge, &Base.encode64(&1, padding: false))
      |> Map.put(:attestationFormats, struct.attestation_formats)
      |> Map.put(:attestationSelection, struct.authenticator_selection)
      |> Map.put(:excludeCredentials, struct.exclude_credentials)
      |> Map.put(:pubKeyCredParams, struct.pub_key_cred_params)
      |> Map.drop([
        :attestation_formats,
        :authenticator_selection,
        :exclude_credentials,
        :pub_key_cred_params
      ])
      |> JSON.encode!(opts)
    end
  end
end
