defmodule Digister.Registers.RegisterField do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @field_types ~w(text long_text number decimal currency email reference_no url date datetime checkbox multi_select dropdown phone time file)

  schema "register_fields" do
    field :label, :string
    field :field_key, :string
    field :field_type, :string
    field :required, :boolean, default: false
    field :is_active, :boolean, default: true
    field :position, :integer, default: 0
    field :options, {:array, :string}
    field :option_colors, {:array, :string}
    field :min_value, :decimal
    field :max_value, :decimal
    field :fill_by, :string

    belongs_to :register, Digister.Registers.Register

    timestamps(type: :naive_datetime)
  end

  def changeset(field, attrs) do
    field
    |> cast(attrs, [:register_id, :label, :field_key, :field_type, :required, :is_active,
                    :position, :options, :option_colors, :min_value, :max_value, :fill_by])
    |> validate_required([:register_id, :label, :field_key, :field_type])
    |> validate_inclusion(:field_type, @field_types)
  end
end
