defmodule WebauthnComponents.Schemas.PubKeyCredParams do
  @moduledoc """
  Struct used to specify the algorithms supported by the host application.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#pubkeycredparams
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive JSON.Encoder
  @derive Jason.Encoder
  embedded_schema do
    field :alg, :integer
    field :type, :string, default: "public-key"
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:alg, :type])
    |> validate_required([:alg, :type])
  end
end
