defmodule WebauthnComponents.WebauthnCredential do
  @moduledoc """
  Struct representing a credential to be used by the WebAuthn API.
  """

  @enforce_keys [:id, :public_key]
  defstruct [:id, :public_key]

  @type t :: %__MODULE__{
          id: binary(),
          public_key: String.t()
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      map = Map.from_struct(struct)

      encoded_public_key =
        for {k, v} <- map[:public_key], into: %{} do
          if is_binary(v) do
            {k, Base.encode64(v)}
          else
            {k, v}
          end
        end

      encoded_map = %{id: Base.encode64(map[:id]), public_key: encoded_public_key}
      Jason.Encode.map(encoded_map, opts)
    end
  end
end
