defmodule Digister.Repo.Migrations.RemoveOwnerPhoneFromOrganisations do
  use Ecto.Migration

  def change do
    alter table(:organisations) do
      remove :owner_phone, :string
    end
  end
end
