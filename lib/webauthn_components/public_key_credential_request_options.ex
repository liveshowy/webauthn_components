defmodule WebauthnComponents.Config.PublicKeyCredentialRequestOptions do
  @moduledoc """
  Struct used to fetch a credential from a client authenticator device.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialRequestOptions
  """
  @type t :: %__MODULE__{
          allow_credentials: [AllowCredential.t()],
          challenge: binary(),
          extensions: map(),
          hints: [String.t()],
          rp_id: String.t() | nil,
          timeout: pos_integer(),
          user_verification: :required | :preferred | :discouraged
        }

  defstruct [
    :challenge,
    :rp_id,
    allow_credentials: [],
    extensions: %{},
    hints: [],
    timeout: :timer.seconds(60),
    user_verification: :preferred
  ]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:challenge, &Base.encode64(&1, padding: false))
      |> Map.put(:rpId, struct.rp_id)
      |> Map.put(:allowCredentials, struct.allow_credentials)
      |> Map.put(:userVerification, struct.user_verification)
      |> Map.drop([:rp_id, :allow_credentials, :user_verification])
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:challenge, &Base.encode64(&1, padding: false))
      |> Map.put(:rpId, struct.rp_id)
      |> Map.put(:allowCredentials, struct.allow_credentials)
      |> Map.put(:userVerification, struct.user_verification)
      |> Map.drop([:rp_id, :allow_credentials, :user_verification])
      |> JSON.encode!(opts)
    end
  end
end
