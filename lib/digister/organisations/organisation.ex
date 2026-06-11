defmodule Digister.Organisations.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organisations" do
    field :name, :string
    field :slug, :string
    field :owner_email, :string
    field :is_active, :boolean, default: true
    field :industry, :string
    field :country, :string
    field :owner, :string
    field :owner_phone, :string
    field :registers_count, :integer, default: 0
    field :entries_count, :integer, default: 0
    field :initials, :string
    field :entries_feed_cleared_at, :naive_datetime

    has_many :registers, Digister.Registers.Register
    has_many :users, Digister.Accounts.User, foreign_key: :organisation_id

    timestamps(type: :naive_datetime)
  end

  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :slug, :owner_email, :is_active, :industry, :country,
                    :owner, :owner_phone, :initials, :entries_feed_cleared_at])
    |> validate_required([:name, :slug])
    |> validate_length(:name, max: 255)
    |> validate_length(:slug, max: 100)
    |> unique_constraint(:slug)
    |> maybe_set_initials()
  end

  defp maybe_set_initials(changeset) do
    if get_field(changeset, :initials) do
      changeset
    else
      name = get_field(changeset, :name)
      if name do
        initials =
          name
          |> String.split()
          |> Enum.take(2)
          |> Enum.map(&String.first/1)
          |> Enum.join()
          |> String.upcase()

        put_change(changeset, :initials, initials)
      else
        changeset
      end
    end
  end
end
