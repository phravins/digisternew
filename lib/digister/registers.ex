defmodule Digister.Registers do
  import Ecto.Query
  alias Digister.Repo
  alias Digister.Registers.{Register, RegisterField, RegisterEntry, RegisterFileUpload}

  def list_registers(organisation_id) do
    Repo.all(
      from r in Register,
        where: r.organisation_id == ^organisation_id and is_nil(r.deleted_at),
        order_by: [asc: r.name]
    )
  end

  def count_registers do
    Repo.aggregate(from(r in Register, where: is_nil(r.deleted_at)), :count, :id)
  end

  def get_register!(id), do: Repo.get!(Register, id)

  def create_register(attrs) do
    %Register{}
    |> Register.changeset(attrs)
    |> Repo.insert()
  end

  def update_register(%Register{} = register, attrs) do
    register
    |> Register.changeset(attrs)
    |> Repo.update()
  end

  def soft_delete_register(%Register{} = register) do
    register
    |> Ecto.Changeset.change(deleted_at: NaiveDateTime.utc_now())
    |> Repo.update()
  end

  # Fields

  def list_fields(register_id) do
    Repo.all(
      from f in RegisterField,
        where: f.register_id == ^register_id and f.is_active == true,
        order_by: [asc: f.position]
    )
  end

  def create_field(attrs) do
    %RegisterField{}
    |> RegisterField.changeset(attrs)
    |> Repo.insert()
  end

  # Entries

  def list_entries(register_id) do
    Repo.all(
      from e in RegisterEntry,
        where: e.register_id == ^register_id and is_nil(e.deleted_at),
        order_by: [asc: e.sequence_number]
    )
  end

  def count_entries do
    Repo.aggregate(from(e in RegisterEntry, where: is_nil(e.deleted_at)), :count, :id)
  end

  def create_entry(attrs) do
    %RegisterEntry{}
    |> RegisterEntry.changeset(attrs)
    |> Repo.insert()
  end

  def soft_delete_entry(%RegisterEntry{} = entry) do
    entry
    |> Ecto.Changeset.change(deleted_at: NaiveDateTime.utc_now())
    |> Repo.update()
  end
end
