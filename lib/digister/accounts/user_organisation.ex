defmodule Digister.Accounts.UserOrganisation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_organisations" do
    field :role, :string

    belongs_to :user, Digister.Accounts.User
    belongs_to :organisation, Digister.Organisations.Organisation

    timestamps(type: :naive_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :organisation_id, :role])
    |> validate_required([:user_id, :organisation_id, :role])
    |> validate_inclusion(:role, ["admin", "member"])
    |> unique_constraint([:user_id, :organisation_id])
  end
end
