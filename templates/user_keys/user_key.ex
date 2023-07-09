defmodule <%= @app_pascal_case %>.UserKeys.UserKey do
  @moduledoc """
  Schema representing a `User`'s Webauthn key.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias <%= @app_pascal_case %>.Users.User
  alias WebauthnComponents.CoseKey

  @type t :: %__MODULE__{
          id: binary(),
          label: String.t(),
          key_id: binary(),
          public_key: map(),
          last_used_at: NaiveDateTime.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  @derive {Jason.Encoder, only: [:key_id, :public_key, :label, :last_used_at]}
  schema "user_keys" do
    field :label, :string, default: "default"
    field :key_id, :binary
    field :public_key, CoseKey
    belongs_to :user, User
    field :last_used_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = user_key, attrs \\ %{}) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label])
  end

  @doc false
  def new_changeset(%__MODULE__{} = user_key, attrs) do
    user_key
    |> cast(attrs, [:user_id, :key_id, :public_key, :label])
    |> validate_required([:user_id, :key_id, :public_key, :label])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :label], message: "label already taken")
    |> unique_constraint([:key_id], message: "key already registered")
    |> put_last_used_at()
  end

  @doc false
  def update_changeset(%__MODULE__{} = user_key, attrs) do
    user_key
    |> cast(attrs, [:label])
    |> validate_required([:label])
    |> unique_constraint([:user_id, :label], message: "label already taken")
    |> put_last_used_at()
  end

  @spec put_last_used_at(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_last_used_at(changeset) do
    put_change(changeset, :last_used_at, NaiveDateTime.utc_now(:second))
  end
end
