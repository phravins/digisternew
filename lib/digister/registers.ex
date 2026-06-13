defmodule Digister.Registers do
  import Ecto.Query
  alias Digister.Repo
  alias Digister.Registers.{Register, RegisterField, RegisterEntry, RegisterFileUpload}

  def list_registers(organisation_id) do
    Repo.all(
      from r in Register,
        where: r.organisation_id == ^organisation_id and is_nil(r.deleted_at) and r.is_template == false,
        order_by: [asc: r.name]
    )
  end

  def count_registers do
    Repo.aggregate(from(r in Register, where: is_nil(r.deleted_at) and r.is_template == false), :count, :id)
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
    |> Ecto.Changeset.change(deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  # Templates

  def list_templates do
    Repo.all(
      from r in Register,
        where: r.is_template == true and is_nil(r.deleted_at),
        order_by: [asc: r.name],
        preload: [:fields]
    )
  end

  def mark_as_template(%Register{} = register) do
    register
    |> Ecto.Changeset.change(is_template: true, organisation_id: nil)
    |> Repo.update()
  end

  def apply_template(template_id, org_id) do
    Repo.transaction(fn ->
      template = Repo.get!(Register, template_id)
      fields = list_fields(template_id)

      case create_register(%{
        name: template.name,
        description: template.description,
        category: template.category,
        is_template: false,
        organisation_id: org_id
      }) do
        {:ok, new_register} ->
          Enum.each(fields, fn f ->
            create_field(%{
              register_id: new_register.id,
              label: f.label,
              field_key: f.field_key,
              field_type: f.field_type,
              required: f.required,
              position: f.position,
              options: f.options,
              option_colors: f.option_colors
            })
          end)
          new_register

        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
  end

  # Bin

  def list_bin do
    Repo.all(
      from r in Register,
        where: not is_nil(r.deleted_at),
        order_by: [desc: r.deleted_at],
        preload: [:organisation]
    )
  end

  def recover_register(%Register{} = register) do
    register
    |> Ecto.Changeset.change(deleted_at: nil)
    |> Repo.update()
  end

  def purge_register(%Register{} = register) do
    Repo.delete(register)
  end

  def purge_expired_bin do
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -60 * 86400, :second)
    Repo.delete_all(from r in Register, where: not is_nil(r.deleted_at) and r.deleted_at < ^cutoff)
  end

  def purge_all_bin do
    Repo.delete_all(from r in Register, where: not is_nil(r.deleted_at))
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

  # File uploads

  def list_file_uploads(register_id) do
    Repo.all(
      from u in RegisterFileUpload,
        where: u.register_id == ^register_id,
        select: %{entry_id: u.entry_id, field_key: u.field_key, original_name: u.original_name}
    )
  end
end
