defmodule WebauthnComponents.AllowCredential do
  @moduledoc """
  Struct representing a credential registered to a user which may be used for authentication.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialRequestOptions#allowcredentials
  """
  @type t :: %__MODULE__{
          id: binary(),
          transports: [String.t()],
          type: String.t()
        }

  @enforce_keys [:id]
  defstruct [:id, transports: [], type: "public-key"]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.update!(:id, &Base.url_encode64(&1, padding: false))
      |> JSON.encode!(opts)
    end
  end
end
