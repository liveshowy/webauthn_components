defmodule WebauthnComponents.Schemas.User do
  @moduledoc """
  Struct used to identify the user to be associated with a credential.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#user
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :display_name, :string
    field :id, :string
    field :name, :string
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:display_name, :id, :name])
    |> validate_required([:display_name, :id, :name])
  end

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
