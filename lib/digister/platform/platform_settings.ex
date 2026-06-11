defmodule Digister.Platform.PlatformSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "platform_settings" do
    field :email_notifications, :boolean, default: true
    field :maintenance_mode, :boolean, default: false
    field :platform_version, :string

    timestamps(type: :naive_datetime)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:email_notifications, :maintenance_mode, :platform_version])
  end
end
