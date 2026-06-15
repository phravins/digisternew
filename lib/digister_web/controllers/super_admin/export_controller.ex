defmodule DigisterWeb.SuperAdmin.ExportController do
  use DigisterWeb, :controller

  import DigisterWeb.SuperAdminAuth, only: [require_super_admin: 2]
  plug :require_super_admin

  alias Digister.Organisations
  alias Digister.Accounts
  alias Digister.Registers

  def register(conn, %{"register_id" => register_id}) do
    register = Registers.get_register!(register_id)
    fields = Registers.list_fields(register_id)
    entries = Registers.list_entries(register_id)

    file_index =
      Registers.list_file_uploads(register_id)
      |> Map.new(fn u -> {{u.entry_id, u.field_key}, u.original_name} end)

    header = ["S.No"] ++ Enum.map(fields, & &1.label) ++ ["Added by"]

    data =
      Enum.with_index(entries, 1)
      |> Enum.map(fn {entry, idx} ->
        cells =
          Enum.map(fields, fn field ->
            export_cell(entry, field, file_index)
          end)

        [idx] ++ cells ++ [entry.added_by_name || ""]
      end)

    filename = "#{slugify(register.name)}_#{Date.utc_today()}.csv"
    send_csv(conn, to_csv([header | data]), filename)
  end

  defp export_cell(entry, field, file_index) do
    cond do
      field.field_type == "file" ->
        Map.get(file_index, {entry.id, field.field_key}) || ""

      true ->
        case Map.get(entry.data || %{}, field.field_key) do
          nil -> ""
          v when is_list(v) -> Enum.join(v, ", ")
          v -> to_string(v)
        end
    end
  end

  defp slugify(name) do
    name
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
    |> then(fn s -> if s == "", do: "register", else: s end)
  end

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

  defp fmt_dt(%NaiveDateTime{} = dt) do
    ist = NaiveDateTime.add(dt, 19800, :second)
    Calendar.strftime(ist, "%d %b %Y %I:%M %p")
  end
  defp fmt_dt(_), do: ""
end
