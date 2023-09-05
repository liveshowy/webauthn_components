defmodule <%= inspect @app_pascal_case %>.Repo.Migrations.CreateUserTokens do
  use Ecto.Migration

  def change do
    create table(:user_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :value, :binary, null: false
      add :type, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(updated_at: false)
    end

    create index(:user_tokens, [:user_id])
  end
end
