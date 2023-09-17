defmodule <%= inspect @app_pascal_case %>.Identity.UserToken do
  @moduledoc """
  Schema representing a token generated for a `User`.

  ## Considerations

  - NaiveDateTime is used by default, and this may result in token validation errors in systems distributed across multiple regions.
  - Email confirmation, invite codes, and other tokens may be implemented by updating the `:type` values and writing additional code in the `Identity` context.
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
    fields = __MODULE__.__schema__(:fields) -- [:value]

    user_token
    |> cast(attrs, fields)
    |> put_change(:value, :crypto.strong_rand_bytes(64))
    |> validate_required([:type, :value])
    |> foreign_key_constraint(:user_id)
  end
end
