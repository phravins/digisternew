defmodule Digister.Activities do
  import Ecto.Query
  alias Digister.Repo
  alias Digister.Activities.Activity

  def list_recent(limit \\ 10) do
    Repo.all(from a in Activity, order_by: [desc: a.inserted_at], limit: ^limit)
  end

  def log(attrs) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end
end
