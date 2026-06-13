defmodule Digister.Activities do
  import Ecto.Query
  alias Digister.Repo
  alias Digister.Activities.Activity

  def list_recent(limit \\ 10) do
    Repo.all(from a in Activity, order_by: [desc: a.inserted_at], limit: ^limit)
  end

  def log(attrs) do
    case %Activity{} |> Activity.changeset(attrs) |> Repo.insert() do
      {:ok, activity} = ok ->
        Phoenix.PubSub.broadcast(Digister.PubSub, "activities", {:activity_logged, activity})
        ok
      {:error, _} = err ->
        err
    end
  end

  def clear_all do
    Repo.delete_all(Activity)
    Phoenix.PubSub.broadcast(Digister.PubSub, "activities", :activities_cleared)
  end
end
