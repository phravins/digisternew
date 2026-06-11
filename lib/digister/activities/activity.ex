defmodule Digister.Activities.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "activities" do
    field :user_name, :string
    field :action, :string
    field :color, :string
    field :metadata, :map

    timestamps(type: :naive_datetime)
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:user_name, :action, :color, :metadata])
    |> validate_required([:action])
  end
end
