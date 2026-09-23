defmodule WebauthnComponents.Schemas.RelyingParty do
  @moduledoc """
  Struct used to identify the application associated with a credential.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#rp
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive JSON.Encoder
  @derive Jason.Encoder
  embedded_schema do
    field :id, :string
    field :name, :string
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:id, :name])
    |> validate_required([:name])
  end
end
