defmodule WebauthnComponents.PublicKeyCredentialCreationOptions do
  @moduledoc """
  Struct representing options for registering a new credential.

  This struct documents the shape of the WebAuthn `PublicKeyCredentialCreationOptions` dictionary. Field keys are converted to camelCase when encoded as JSON.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
  - https://w3c.github.io/webauthn/#dictionary-makecredentialoptions
  """
  alias WebauthnComponents.AuthenticatorSelection
  alias WebauthnComponents.ExcludedCredential
  alias WebauthnComponents.PubKeyCredParams
  alias WebauthnComponents.User
  alias WebauthnComponents.RelyingParty

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

  @enforce_keys [:rp, :user]

  defstruct [
    :challenge,
    :rp,
    :user,
    attestation: :none,
    attestation_formats: [],
    pub_key_cred_params: [
      %PubKeyCredParams{alg: -8},
      %PubKeyCredParams{alg: -7},
      %PubKeyCredParams{alg: -257}
    ],
    authenticator_selection: %AuthenticatorSelection{
      authenticator_attachment: :platform,
      resident_key: :required,
      user_verification: :required
    },
    hints: [],
    exclude_credentials: [],
    extensions: [],
    timeout: :timer.seconds(60)
  ]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:challenge, &Base.url_encode64(&1, padding: false))
      |> Map.put(:attestationFormats, struct.attestation_formats)
      |> Map.put(:authenticatorSelection, struct.authenticator_selection)
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
      |> Map.update!(:challenge, &Base.url_encode64(&1, padding: false))
      |> Map.put(:attestationFormats, struct.attestation_formats)
      |> Map.put(:authenticatorSelection, struct.authenticator_selection)
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
