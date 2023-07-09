defmodule <%= inspect @app_pascal_case %>.Repo.Migrations.CreateUserKeys do
  use Ecto.Migration

  def change do
    create table(:user_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :label, :string, null: false
      add :key_id, :binary, null: false
      add :public_key, :binary, null: false
      add :last_used, :utc_datetime, null: false

      timestamps()
    end

    create index(:user_keys, [:user_id])
    create unique_index(:user_keys, [:key_id])
    create unique_index(:user_keys, [:user_id, :label])
  end
end
