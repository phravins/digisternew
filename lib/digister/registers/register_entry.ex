defmodule Digister.Registers.RegisterEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "register_entries" do
    field :added_by_name, :string
    field :data, :map
    field :sequence_number, :integer
    field :deleted_at, :naive_datetime

    belongs_to :register, Digister.Registers.Register
    belongs_to :organisation, Digister.Organisations.Organisation
    belongs_to :added_by, Digister.Accounts.User

    has_many :file_uploads, Digister.Registers.RegisterFileUpload, foreign_key: :entry_id

    timestamps(type: :naive_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:register_id, :organisation_id, :added_by_id, :added_by_name, :data, :sequence_number])
    |> validate_required([:register_id, :organisation_id])
  end
end
