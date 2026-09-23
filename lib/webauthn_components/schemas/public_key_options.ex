defmodule WebauthnComponents.Schemas.PublicKeyOptions do
  @moduledoc """
  Struct representing options for registering a new credential.

  The struct is defined as an Ecto embedded schema to document the shape and provide guidance during implementation. The field keys are converted to camelCase when encoded as JSON.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions
  - https://w3c.github.io/webauthn/#dictionary-makecredentialoptions
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias WebauthnComponents.Schemas.AuthenticatorSelection
  alias WebauthnComponents.Schemas.ExcludedCredential
  alias WebauthnComponents.Schemas.PubKeyCredParams
  alias WebauthnComponents.Schemas.User
  alias WebauthnComponents.Schemas.RelyingParty

  @primary_key false
  embedded_schema do
    field :attestation, Ecto.Enum,
      values: [:none, :direct, :enterprise, :indirect],
      default: :none

    field :attestation_formats, {:array, :string}, default: []
    embeds_one :authenticator_selection, AuthenticatorSelection
    field :challenge, :binary, default: nil
    embeds_many :exclude_credentials, ExcludedCredential
    field :extensions, :map, default: %{}
    field :hints, {:array, :string}, default: []
    embeds_many :pub_key_cred_params, PubKeyCredParams
    embeds_one :rp, RelyingParty
    field :timeout, :integer, default: :timer.seconds(60)
    embeds_one :user, User
  end

  def changeset(%__MODULE__{} = struct, params) do
    casts = [
      :attestation,
      :attestation_formats,
      :challenge,
      :extensions,
      :hints,
      :timeout
    ]

    struct
    |> cast(params, casts)
    |> validate_required([:challenge])
    |> cast_embed(:authenticator_selection, required: false)
    |> cast_embed(:exclude_credentials, required: false)
    |> cast_embed(:pub_key_cred_params, required: true)
    |> cast_embed(:rp, required: true)
    |> cast_embed(:user, required: true)
  end

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
