defmodule Digister.Organisations do
  import Ecto.Query
  alias Digister.Repo
  alias Digister.Organisations.Organisation

  def list_organisations do
    Repo.all(from o in Organisation, order_by: [desc: o.inserted_at])
  end

  def list_organisations_with_register_counts do
    Repo.all(
      from o in Organisation,
        left_join: r in Digister.Registers.Register,
          on: r.organisation_id == o.id and is_nil(r.deleted_at),
        group_by: o.id,
        order_by: [desc: o.inserted_at],
        select: %{
          id: o.id,
          name: o.name,
          slug: o.slug,
          industry: o.industry,
          owner: o.owner,
          owner_email: o.owner_email,
          is_active: o.is_active,
          entries_count: o.entries_count,
          inserted_at: o.inserted_at,
          registers_count: count(r.id)
        }
    )
  end

  def list_active_organisations do
    Repo.all(from o in Organisation, where: o.is_active == true, order_by: [asc: o.name])
  end

  def count_organisations do
    Repo.aggregate(Organisation, :count, :id)
  end

  def get_organisation!(id), do: Repo.get!(Organisation, id)

  def get_organisation_by_slug(slug), do: Repo.get_by(Organisation, slug: slug)

  def create_organisation(attrs) do
    %Organisation{}
    |> Organisation.changeset(attrs)
    |> Repo.insert()
  end

  def update_organisation(%Organisation{} = org, attrs) do
    org
    |> Organisation.changeset(attrs)
    |> Repo.update()
  end

  def delete_organisation(%Organisation{} = org) do
    Repo.update(Organisation.changeset(org, %{is_active: false}))
  end
end
