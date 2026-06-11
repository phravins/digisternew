defmodule Digister.Repo do
  use Ecto.Repo,
    otp_app: :digister,
    adapter: Ecto.Adapters.Postgres
end
