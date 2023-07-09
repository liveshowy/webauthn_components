defmodule <%= @app_pascal_case %>.UserTokens.UserToken do
  @moduledoc """
  Schema representing a token generated for a `User`.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias <%= @app_pascal_case %>.Users.User

  @type t :: %__MODULE__{
          id: binary(),
          context: atom(),
          token: binary(),
          user_id: binary(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "user_tokens" do
    field :context, Ecto.Enum, values: [:session], default: :session
    field :token, :binary
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = user_token, attrs) do
    user_token
    |> cast(attrs, [:token, :context, :user_id])
    |> validate_required([:token, :context, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
