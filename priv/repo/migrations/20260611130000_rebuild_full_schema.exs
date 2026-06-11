defmodule Digister.Repo.Migrations.RebuildFullSchema do
  use Ecto.Migration

  def up do
    # Drop existing tables (reverse FK order)
    drop_if_exists table(:users_tokens)
    drop_if_exists table(:users)

    # Rebuild users with UUID PK and full schema fields
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string
      add :email, :citext, null: false
      add :hashed_password, :string, redact: true
      add :confirmed_at, :utc_datetime
      add :is_super_admin, :boolean, default: false, null: false
      add :role, :string, default: "member"
      add :is_active, :boolean, default: true, null: false
      add :signed_on, :naive_datetime
      add :metabase_id, :integer
      add :avatar, :binary
      add :avatar_content_type, :string
      add :two_fa_enabled, :boolean, default: false, null: false
      add :otp_code, :string
      add :otp_expires_at, :naive_datetime
      add :organisation_id, :binary_id

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:organisation_id])
    create index(:users, [:is_super_admin])

    # Rebuild users_tokens with UUID FK
    create table(:users_tokens) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # organisations
    create table(:organisations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :owner_email, :string
      add :is_active, :boolean, default: true, null: false
      add :industry, :string
      add :country, :string
      add :owner, :string
      add :owner_phone, :string
      add :registers_count, :integer, default: 0, null: false
      add :entries_count, :integer, default: 0, null: false
      add :initials, :string
      add :entries_feed_cleared_at, :naive_datetime

      timestamps(type: :naive_datetime)
    end

    create unique_index(:organisations, [:slug])
    create index(:organisations, [:is_active])

    # registers
    create table(:registers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :category, :string
      add :is_active, :boolean, default: true, null: false
      add :entries_count, :integer, default: 0, null: false
      add :deleted_at, :naive_datetime
      add :organisation_id, references(:organisations, type: :binary_id, on_delete: :nilify_all)
      add :assigned_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :naive_datetime)
    end

    create index(:registers, [:organisation_id])
    create index(:registers, [:assigned_user_id])
    create index(:registers, [:deleted_at])

    # register_fields
    create table(:register_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :register_id, references(:registers, type: :binary_id, on_delete: :delete_all), null: false
      add :label, :string, null: false
      add :field_key, :string, null: false
      add :field_type, :string, null: false
      add :required, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false
      add :position, :integer, default: 0, null: false
      add :options, {:array, :string}
      add :option_colors, {:array, :string}
      add :min_value, :decimal
      add :max_value, :decimal
      add :fill_by, :string

      timestamps(type: :naive_datetime)
    end

    create index(:register_fields, [:register_id])
    create index(:register_fields, [:register_id, :position])

    # register_entries
    create table(:register_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :register_id, references(:registers, type: :binary_id, on_delete: :delete_all), null: false
      add :organisation_id, references(:organisations, type: :binary_id, on_delete: :delete_all), null: false
      add :added_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :added_by_name, :string
      add :data, :map
      add :sequence_number, :integer
      add :deleted_at, :naive_datetime

      timestamps(type: :naive_datetime)
    end

    create index(:register_entries, [:register_id])
    create index(:register_entries, [:organisation_id])
    create index(:register_entries, [:added_by_id])
    create index(:register_entries, [:deleted_at])

    # register_users (join table — no timestamps per spec)
    create table(:register_users, primary_key: false) do
      add :register_id, references(:registers, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
    end

    create unique_index(:register_users, [:register_id, :user_id])

    # register_file_uploads
    create table(:register_file_uploads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :register_id, references(:registers, type: :binary_id, on_delete: :delete_all), null: false
      add :entry_id, references(:register_entries, type: :binary_id, on_delete: :delete_all), null: false
      add :field_key, :string, null: false
      add :original_name, :string
      add :file_data, :binary
      add :content_type, :string
      add :file_size, :integer

      timestamps(type: :naive_datetime)
    end

    create index(:register_file_uploads, [:register_id])
    create index(:register_file_uploads, [:entry_id])

    # notifications
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :title, :string
      add :body, :text
      add :type, :string
      add :is_read, :boolean, default: false, null: false
      add :org_name, :string
      add :admin_name, :string
      add :related_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :naive_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:is_read])

    # activities
    create table(:activities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_name, :string
      add :action, :string
      add :color, :string
      add :metadata, :map

      timestamps(type: :naive_datetime)
    end

    # platform_settings (singleton row, integer PK)
    create table(:platform_settings) do
      add :email_notifications, :boolean, default: true, null: false
      add :maintenance_mode, :boolean, default: false, null: false
      add :platform_version, :string

      timestamps(type: :naive_datetime)
    end
  end

  def down do
    drop_if_exists table(:platform_settings)
    drop_if_exists table(:activities)
    drop_if_exists table(:notifications)
    drop_if_exists table(:register_file_uploads)
    drop_if_exists table(:register_users)
    drop_if_exists table(:register_entries)
    drop_if_exists table(:register_fields)
    drop_if_exists table(:registers)
    drop_if_exists table(:organisations)
    drop_if_exists table(:users_tokens)
    drop_if_exists table(:users)

    # Restore original users + users_tokens
    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :is_super_admin, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
