defmodule WebauthnComponents.Schemas.AuthenticatorSelection do
  @moduledoc """
  Struct used to constrain allowed authenticators used to create a new credential.

  Note that `requireResidentKey` is soft-deprecated in the W3 spec, so there is no `:require_resident_key` field in this struct. Use the `:resident_key` field to apply constraints for discoverable credentials.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#authenticatorselection
  - - https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API#discoverable_and_non-discoverable_credentials
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :authenticator_attachment, Ecto.Enum,
      values: [:platform, :"cross-platform"],
      default: nil

    field :resident_key, Ecto.Enum,
      values: [:discouraged, :preferred, :required],
      default: :required

    field :user_verification, Ecto.Enum,
      values: [:discouraged, :preferred, :required],
      default: :preferred
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:authenticator_attachment, :resident_key, :user_verification])
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.put(:authenticatorAttachment, struct.authenticator_attachment)
      |> Map.put(:residentkey, struct.resident_key)
      |> Map.put(:userVerification, struct.user_verification)
      |> Map.drop([:authenticator_attachment, :resident_key, :user_verification])
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.put(:authenticatorAttachment, struct.authenticator_attachment)
      |> Map.put(:residentkey, struct.resident_key)
      |> Map.put(:userVerification, struct.user_verification)
      |> Map.drop([:authenticator_attachment, :resident_key, :user_verification])
      |> JSON.encode!(opts)
    end
  end
end
