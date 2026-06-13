defmodule DigisterWeb.SuperAdmin.BinLive do
  use DigisterWeb, :live_view

  alias Digister.Registers

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    registers = Registers.list_bin()

    {:ok,
     socket
     |> assign(:page_title, "Bin")
     |> assign(:active_nav, :bin)
     |> assign(:registers, registers)}
  end

  def handle_event("recover", %{"id" => id}, socket) do
    register = Registers.get_register!(id)
    Registers.recover_register(register)
    registers = Registers.list_bin()
    {:noreply,
     socket
     |> assign(:registers, registers)
     |> put_flash(:info, "\"#{register.name}\" has been recovered successfully.")}
  end

  def handle_event("purge", %{"id" => id}, socket) do
    register = Registers.get_register!(id)
    Registers.purge_register(register)
    registers = Registers.list_bin()
    {:noreply,
     socket
     |> assign(:registers, registers)
     |> put_flash(:info, "\"#{register.name}\" permanently deleted.")}
  end

  defp days_remaining(%NaiveDateTime{} = deleted_at) do
    diff_seconds = NaiveDateTime.diff(NaiveDateTime.utc_now(), deleted_at, :second)
    max(0, 60 - div(diff_seconds, 86400))
  end

  defp days_badge_class(days) when days > 30, do: "bg-green-50 text-green-700 border-green-200"
  defp days_badge_class(days) when days > 10, do: "bg-orange-50 text-orange-600 border-orange-200"
  defp days_badge_class(_), do: "bg-red-50 text-red-600 border-red-200"

  defp fmt_date(%NaiveDateTime{} = dt) do
    ist = NaiveDateTime.add(dt, 19800, :second)
    Calendar.strftime(ist, "%d %b %Y · %I:%M %p")
  end
  defp fmt_date(_), do: "—"

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-xl font-bold text-gray-900">Bin</h1>
        <p class="text-sm text-gray-500 mt-0.5">Deleted registers are kept for 60 days before permanent removal</p>
      </div>
      <div class="flex items-center gap-2 text-xs text-gray-400 bg-gray-50 border border-gray-200 rounded-lg px-3 py-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        Auto-purge after 60 days
      </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <%= if @registers == [] do %>
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <svg class="w-12 h-12 text-gray-200 mb-3" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
          <p class="text-sm font-medium text-gray-400">Bin is empty</p>
          <p class="text-xs text-gray-300 mt-1">Deleted registers will appear here for 60 days</p>
        </div>
      <% else %>
        <table class="w-full text-sm">
          <thead class="bg-gray-50 border-b border-gray-100">
            <tr>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Register</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Company</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Deleted On</th>
              <th class="text-left px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Days Left</th>
              <th class="text-right px-6 py-3 text-xs font-semibold text-gray-400 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr :for={r <- @registers} class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4">
                <div class="flex items-center gap-3">
                  <div class="w-7 h-7 rounded-lg bg-red-50 flex items-center justify-center flex-shrink-0">
                    <svg class="w-3.5 h-3.5 text-red-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </div>
                  <div>
                    <p class="font-medium text-gray-700">{r.name}</p>
                    <p :if={r.description} class="text-xs text-gray-400 mt-0.5">{r.description}</p>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">
                {if r.organisation, do: r.organisation.name, else: "—"}
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">{fmt_date(r.deleted_at)}</td>
              <td class="px-6 py-4">
                <% days = days_remaining(r.deleted_at) %>
                <span class={["inline-flex items-center text-xs font-semibold border rounded-full px-2.5 py-0.5", days_badge_class(days)]}>
                  {days}d left
                </span>
              </td>
              <td class="px-6 py-4">
                <div class="flex items-center gap-2 justify-end">
                  <button type="button" phx-click="recover" phx-value-id={r.id}
                    class="text-xs px-3 py-1.5 bg-green-50 text-green-700 border border-green-200 rounded-lg font-medium hover:bg-green-100 transition-colors whitespace-nowrap">
                    Recover
                  </button>
                  <button type="button" phx-click="purge" phx-value-id={r.id}
                    class="text-xs px-3 py-1.5 border border-gray-200 text-gray-400 rounded-lg hover:text-red-500 hover:border-red-200 transition-colors whitespace-nowrap">
                    Delete Now
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end
end
