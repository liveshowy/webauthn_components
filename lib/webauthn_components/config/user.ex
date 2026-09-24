defmodule WebauthnComponents.Config.User do
  @moduledoc """
  Struct used to identify the user to be associated with a credential.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#user
  """

  @type t :: %__MODULE__{
          display_name: String.t(),
          id: String.t() | binary(),
          name: String.t()
        }

  @enforce_keys [:id, :name, :display_name]
  defstruct [:id, :name, :display_name]

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.put(:displayName, struct.display_name)
      |> Map.drop([:display_name])
      |> Jason.Encode.map(opts)
    end
  end

  defimpl JSON.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      struct
      |> Map.from_struct()
      |> Map.put(:displayName, struct.display_name)
      |> Map.drop([:display_name])
      |> JSON.encode!(opts)
    end
  end
end
