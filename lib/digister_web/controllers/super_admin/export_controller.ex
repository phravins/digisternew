defmodule DigisterWeb.SuperAdmin.ExportController do
  use DigisterWeb, :controller

  import DigisterWeb.SuperAdminAuth, only: [require_super_admin: 2]
  plug :require_super_admin

  alias Digister.Organisations
  alias Digister.Accounts

  def companies(conn, _params) do
    orgs = Organisations.list_organisations()

    header = ["S.No", "Company", "Industry", "Created", "Status"]

    data =
      Enum.with_index(orgs, 1)
      |> Enum.map(fn {org, idx} ->
        [
          idx,
          org.name,
          org.industry || "",
          fmt_date(org.inserted_at),
          if(org.is_active, do: "Active", else: "Inactive")
        ]
      end)

    send_csv(conn, to_csv([header | data]), "companies_#{Date.utc_today()}.csv")
  end

  def users(conn, _params) do
    users = Accounts.list_users_with_orgs()

    header = ["S.No", "Name", "Email", "Company", "Role", "Status", "Last Active"]

    data =
      Enum.with_index(users, 1)
      |> Enum.map(fn {u, idx} ->
        [
          idx,
          u.username || "",
          u.email,
          u.org_name || "",
          u.role || "",
          if(u.is_active, do: "Active", else: "Inactive"),
          fmt_dt(u.signed_on)
        ]
      end)

    send_csv(conn, to_csv([header | data]), "users_#{Date.utc_today()}.csv")
  end

  defp to_csv(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Enum.map(fn cell ->
        val = to_string(cell)
        if String.contains?(val, [",", "\"", "\n"]) do
          "\"#{String.replace(val, "\"", "\"\"")}\""
        else
          val
        end
      end)
      |> Enum.join(",")
    end)
    |> Enum.join("\r\n")
  end

  defp send_csv(conn, csv, filename) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv)
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: ""

  defp fmt_dt(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y %I:%M %p")
  defp fmt_dt(_), do: ""
end
