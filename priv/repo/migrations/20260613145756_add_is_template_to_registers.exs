defmodule Digister.Repo.Migrations.AddIsTemplateToRegisters do
  use Ecto.Migration

  def change do
    alter table(:registers) do
      add :is_template, :boolean, default: false, null: false
    end
  end
end
