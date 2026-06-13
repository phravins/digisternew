# Seed super admin user
# Run: mix run priv/repo/seeds.exs

alias Digister.Accounts

# Credentials are read from environment variables (loaded from .env in dev)
# so they are never hardcoded in source files.
super_admin_email =
  System.get_env("SUPER_ADMIN_EMAIL") ||
    raise "SUPER_ADMIN_EMAIL is not set (add it to .env)"

super_admin_password =
  System.get_env("SUPER_ADMIN_PASSWORD") ||
    raise "SUPER_ADMIN_PASSWORD is not set (add it to .env)"

case Accounts.get_user_by_email(super_admin_email) do
  nil ->
    case Accounts.register_super_admin(%{
      email: super_admin_email,
      password: super_admin_password
    }) do
      {:ok, user} ->
        IO.puts("Super admin created: #{user.email}")

      {:error, changeset} ->
        IO.puts("Failed to create super admin:")
        IO.inspect(changeset.errors)
    end

  existing ->
    IO.puts("Super admin already exists: #{existing.email}")
end
