defmodule DigisterWeb.Admin.SelectCompanyLive do
  use DigisterWeb, :live_view

  alias Digister.Accounts

  on_mount {DigisterWeb.Admin.AdminAuth, :require_user}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    companies = Accounts.list_user_organisations(user.id)

    {:ok,
     socket
     |> assign(:page_title, "Select a company")
     |> assign(:companies, companies)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center px-4 py-12">
      <div class="w-full max-w-md">
        <div class="text-center mb-8">
          <h1 class="text-2xl font-bold text-gray-900">Select a company</h1>
          <p class="text-sm text-gray-500 mt-1">Choose a workspace to continue.</p>
        </div>

        <%= if @companies == [] do %>
          <div class="bg-white rounded-xl border border-gray-200 px-6 py-12 text-center">
            <p class="text-sm font-medium text-gray-700">No companies assigned</p>
            <p class="text-xs text-gray-400 mt-1">Ask your administrator to grant you access to a company.</p>
            <form action={~p"/users/log-out"} method="post" class="mt-4">
              <input type="hidden" name="_method" value="delete" />
              <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
              <button type="submit" class="text-xs text-indigo-600 hover:underline">Sign out</button>
            </form>
          </div>
        <% else %>
          <div class="space-y-3">
            <a :for={c <- @companies} href={~p"/digisters/#{c.organisation.slug}/admin"}
              class="flex items-center justify-between bg-white rounded-xl border border-gray-200 px-5 py-4 hover:border-indigo-300 hover:shadow-sm transition-all group">
              <div class="flex items-center gap-3 min-w-0">
                <div class="w-9 h-9 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold flex-shrink-0">
                  {c.organisation.name |> to_string() |> String.first() |> to_string() |> String.upcase()}
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-gray-900 text-sm truncate">{c.organisation.name}</p>
                  <p class="text-xs text-gray-400 capitalize">{if c.role == "admin", do: "Admin", else: "User"}</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-gray-300 group-hover:text-indigo-500 transition-colors" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </a>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
