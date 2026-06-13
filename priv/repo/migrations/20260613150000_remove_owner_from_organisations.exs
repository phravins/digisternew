defmodule Digister.Repo.Migrations.RemoveOwnerFromOrganisations do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      remove :owner, :string
      remove :owner_email, :string
    end
  end
end
