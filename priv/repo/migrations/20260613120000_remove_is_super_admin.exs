defmodule Digister.Repo.Migrations.RemoveIsSuperAdmin do
  use Ecto.Migration

  def up do
    execute "UPDATE users SET role = 'super_admin' WHERE is_super_admin = true"
    alter table(:users) do
      remove :is_super_admin
    end
  end

  def down do
    alter table(:users) do
      add :is_super_admin, :boolean, default: false, null: false
    end
    execute "UPDATE users SET is_super_admin = true WHERE role = 'super_admin'"
  end
end
