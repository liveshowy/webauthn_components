defmodule <%= inspect @app_pascal_case %>.Identity.User do
  @moduledoc """
  Schema representing a user of the application.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias <%= inspect @app_pascal_case %>.Identity.UserKey
  alias <%= inspect @app_pascal_case %>.Identity.UserToken

  @type t :: %__MODULE__{
          id: binary(),
          email: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  # Ecto.ULID is used to prevent user enumeration attacks while maintaining sortability.
  # UUIDv7 may provide the same functionality, but it is not fully supported as of 09/2023.
  # Spec: https://github.com/ulid/spec
  # Context: https://www.honeybadger.io/blog/uuids-and-ulids/

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "users" do
    field :email, :string
    has_many :keys, UserKey, preload_order: [desc: :last_used_at]
    has_many :tokens, UserToken, preload_order: [desc: :inserted_at]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    fields = __MODULE__.__schema__(:fields)

    user
    |> cast(attrs, fields)
    |> validate_required([:email])
    |> validate_length(:email, min: 6, max: 120)
    |> validate_format(:email, ~r/@/)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email)
    |> cast_assoc(:keys)
    |> cast_assoc(:tokens)
  end
end
