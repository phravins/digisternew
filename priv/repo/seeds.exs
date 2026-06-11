# Seed super admin user
# Run: mix run priv/repo/seeds.exs

alias Digister.Accounts

super_admin_email = "admin@realoffice.in"

case Accounts.get_user_by_email(super_admin_email) do
  nil ->
    case Accounts.register_super_admin(%{
      email: super_admin_email,
      password: "Admin@2026"
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
