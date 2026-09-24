defmodule WebauthnComponents.Config.AuthenticatorSelection do
  @moduledoc """
  Struct used to constrain allowed authenticators used to create a new credential.

  Note that `requireResidentKey` is soft-deprecated in the W3 spec, so there is no `:require_resident_key` field in this struct. Use the `:resident_key` field to apply constraints for discoverable credentials.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#authenticatorselection
  - https://developer.mozilla.org/en-US/docs/Web/API/Web_Authentication_API#discoverable_and_non-discoverable_credentials
  """

  @type t :: %__MODULE__{
          authenticator_attachment: :platform | :"cross-platform",
          resident_key: :discouraged | :preferred | :required,
          user_verification: :discouraged | :preferred | :required
        }

  defstruct [:authenticator_attachment, :resident_key, :user_verification]

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
