defmodule DigisterWeb.Admin.RegistersLive do
  use DigisterWeb, :live_view

  alias Digister.Registers

  on_mount {DigisterWeb.Admin.AdminAuth, :require_admin}

  def mount(_params, _session, socket) do
    org = socket.assigns.current_organisation
    registers = Registers.list_registers(org.id)

    {:ok,
     socket
     |> assign(:page_title, "Registers")
     |> assign(:active_nav, :registers)
     |> assign(:registers, registers)}
  end

  def render(assigns) do
    ~H"""
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">Registers</h1>
      <p class="text-sm text-gray-500 mt-0.5">Registers for {@current_organisation.name}</p>
    </div>

    <%= if @registers == [] do %>
      <div class="bg-white rounded-xl border border-gray-200 px-6 py-16 text-center">
        <p class="text-sm font-medium text-gray-700">No registers yet</p>
        <p class="text-xs text-gray-400 mt-0.5">Registers created for this company will appear here.</p>
      </div>
    <% else %>
      <div class="space-y-3">
        <div :for={reg <- @registers}
          class="flex items-center justify-between bg-white rounded-xl border border-gray-200 px-5 py-4">
          <div class="min-w-0">
            <p class="font-semibold text-gray-900 text-sm truncate">{reg.name}</p>
            <p class="text-xs text-gray-400 mt-0.5">
              {reg.entries_count} {if reg.entries_count == 1, do: "entry", else: "entries"} · {fmt_date(reg.inserted_at)}
            </p>
          </div>
          <span class={[
            "inline-flex flex-shrink-0 items-center rounded-full border px-2.5 py-0.5 text-xs font-medium",
            if(reg.is_active, do: "bg-green-50 border-green-200 text-green-700", else: "bg-gray-50 border-gray-200 text-gray-500")
          ]}>
            {if reg.is_active, do: "Active", else: "Inactive"}
          </span>
        </div>
      </div>
    <% end %>
    """
  end

  defp fmt_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d %b %Y")
  defp fmt_date(_), do: "—"
end
