defmodule WebauthnComponents.WebauthnUser do
  @moduledoc """
  Struct representing required fields used by the WebAuthn API.
  """
  @enforce_keys [:id, :name, :display_name]
  defstruct [:id, :name, :display_name]

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          display_name: String.t()
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.put(:displayName, struct.display_name)
      |> Map.delete(:display_name)
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, encoder) do
      struct
      |> Map.from_struct()
      |> Map.put(:displayName, struct.display_name)
      |> Map.delete(:display_name)
      |> JSON.encode!(encoder)
    end
  end
end
