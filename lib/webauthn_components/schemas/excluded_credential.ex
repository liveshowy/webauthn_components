defmodule WebauthnComponents.Schemas.ExcludedCredential do
  @moduledoc """
  Struct representing credentials which are already associated with the user, which should not be duplicated.

  ## Resources

  - https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#excludecredentials
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive JSON.Encoder
  @derive Jason.Encoder
  embedded_schema do
    field :id, :string
    field :transports, {:array, Ecto.Enum}, values: [:ble, :hybrid, :internal, :nfc, :usb]
    field :type, :string, default: "public-key"
  end

  def changeset(%__MODULE__{} = struct, params) do
    struct
    |> cast(params, [:id, :transports, :type])
    |> validate_required([:id, :type])
  end
end
