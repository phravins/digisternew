defmodule Digister.Registers.Register do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "registers" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :is_active, :boolean, default: true
    field :entries_count, :integer, default: 0
    field :deleted_at, :naive_datetime

    belongs_to :organisation, Digister.Organisations.Organisation
    belongs_to :assigned_user, Digister.Accounts.User

    has_many :fields, Digister.Registers.RegisterField, foreign_key: :register_id
    has_many :entries, Digister.Registers.RegisterEntry, foreign_key: :register_id

    many_to_many :users, Digister.Accounts.User,
      join_through: "register_users",
      join_keys: [register_id: :id, user_id: :id]

    timestamps(type: :naive_datetime)
  end

  def changeset(register, attrs) do
    register
    |> cast(attrs, [:name, :description, :category, :is_active, :organisation_id, :assigned_user_id])
    |> validate_required([:name, :organisation_id])
    |> validate_length(:name, max: 255)
  end
end
