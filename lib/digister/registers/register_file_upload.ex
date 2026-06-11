defmodule Digister.Registers.RegisterFileUpload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "register_file_uploads" do
    field :field_key, :string
    field :original_name, :string
    field :file_data, :binary
    field :content_type, :string
    field :file_size, :integer

    belongs_to :register, Digister.Registers.Register
    belongs_to :entry, Digister.Registers.RegisterEntry

    timestamps(type: :naive_datetime)
  end

  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:register_id, :entry_id, :field_key, :original_name,
                    :file_data, :content_type, :file_size])
    |> validate_required([:register_id, :entry_id, :field_key])
  end
end
