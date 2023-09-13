defmodule <%= inspect @app_pascal_case %>.Identity.UserToken do
  @moduledoc """
  Schema representing a token generated for a `User`.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Identity.User

  @type t :: %__MODULE__{
          id: binary(),
          type: atom(),
          value: binary(),
          user_id: binary(),
          inserted_at: NaiveDateTime.t(),
        }

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "user_tokens" do
    field :type, Ecto.Enum, values: [:session], default: :session
    field :value, :binary
    belongs_to :user, User

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(%__MODULE__{} = user_token, attrs) do
    fields = __MODULE__.__schema__(:fields)

    user_token
    |> cast(attrs, fields)
    |> validate_required([:type, :value, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
