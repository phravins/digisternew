defmodule Digister.Repo.Migrations.CreateUserOrganisations do
  use Ecto.Migration

  def change do
    create table(:user_organisations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :organisation_id, references(:organisations, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false

      timestamps(type: :naive_datetime)
    end

    create unique_index(:user_organisations, [:user_id, :organisation_id])
    create index(:user_organisations, [:user_id])
    create index(:user_organisations, [:organisation_id])
  end
end
