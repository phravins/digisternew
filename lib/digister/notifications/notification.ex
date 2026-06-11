defmodule Digister.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :title, :string
    field :body, :string
    field :type, :string
    field :is_read, :boolean, default: false
    field :org_name, :string
    field :admin_name, :string

    belongs_to :user, Digister.Accounts.User
    belongs_to :related_user, Digister.Accounts.User

    timestamps(type: :naive_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :title, :body, :type, :is_read, :org_name, :admin_name, :related_user_id])
    |> validate_required([:user_id])
  end
end
