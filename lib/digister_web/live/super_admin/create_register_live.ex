defmodule DigisterWeb.SuperAdmin.CreateRegisterLive do
  use DigisterWeb, :live_view

  alias Digister.Registers
  alias Digister.Organisations

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(_params, _session, socket) do
    orgs = Organisations.list_organisations()

    {:ok,
     socket
     |> assign(:page_title, "Create Register")
     |> assign(:active_nav, :new_register)
     |> assign(:orgs, orgs)
     |> assign(:fields, [])
     |> assign(:errors, %{})
     |> assign(:next_id, 0)}
  end

  def handle_event("add_field", %{"type" => type}, socket) do
    new_field = %{id: socket.assigns.next_id, label: "", type: type, required: false}

    {:noreply,
     socket
     |> assign(:fields, socket.assigns.fields ++ [new_field])
     |> assign(:next_id, socket.assigns.next_id + 1)}
  end

  def handle_event("remove_field", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    fields = Enum.reject(socket.assigns.fields, &(&1.id == id))
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("toggle_required", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id, do: %{f | required: !f.required}, else: f
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("save", params, socket) do
    name = String.trim(params["name"] || "")
    desc = params["description"] || ""
    org_id = params["organisation_id"] || ""

    errors =
      %{}
      |> then(fn e -> if name == "", do: Map.put(e, :name, "Register name is required."), else: e end)

    if errors == %{} do
      attrs = %{
        name: name,
        description: if(String.trim(desc) == "", do: nil, else: String.trim(desc)),
        organisation_id: if(String.trim(org_id) == "", do: nil, else: org_id)
      }

      case Registers.create_register(attrs) do
        {:ok, register} ->
          Enum.each(socket.assigns.fields, fn field ->
            label = String.trim(params["label_#{field.id}"] || "")
            effective_label = if label == "", do: type_label(field.type), else: label

            Registers.create_field(%{
              register_id: register.id,
              label: effective_label,
              field_key: slugify(effective_label) <> "_#{field.id}",
              field_type: field.type,
              required: field.required,
              position: field.id
            })
          end)

          {:noreply,
           socket
           |> put_flash(:info, "Register \"#{name}\" created successfully.")
           |> push_navigate(to: ~p"/digisters/superadmin/registers")}

        {:error, changeset} ->
          db_errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
            |> Enum.map(fn {k, [v | _]} -> {k, v} end)
            |> Map.new()

          {:noreply, assign(socket, :errors, db_errors)}
      end
    else
      {:noreply, assign(socket, :errors, errors)}
    end
  end

  defp slugify(label) do
    label
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.trim("_")
    |> then(fn s -> if s == "", do: "field", else: s end)
  end

  defp type_label("text"), do: "Text"
  defp type_label("number"), do: "Number"
  defp type_label("currency"), do: "Currency"
  defp type_label("date"), do: "Date"
  defp type_label("select"), do: "Dropdown"
  defp type_label("checkbox"), do: "Checkbox"
  defp type_label("long_text"), do: "Long Text"
  defp type_label("email"), do: "Email"
  defp type_label("phone"), do: "Phone"
  defp type_label("formula"), do: "Formula"
  defp type_label(t), do: String.capitalize(t)

  defp type_color("text"), do: "bg-blue-50 text-blue-600 border-blue-100"
  defp type_color("number"), do: "bg-purple-50 text-purple-600 border-purple-100"
  defp type_color("currency"), do: "bg-green-50 text-green-600 border-green-100"
  defp type_color("date"), do: "bg-orange-50 text-orange-600 border-orange-100"
  defp type_color("select"), do: "bg-indigo-50 text-indigo-600 border-indigo-100"
  defp type_color("checkbox"), do: "bg-pink-50 text-pink-600 border-pink-100"
  defp type_color("long_text"), do: "bg-gray-100 text-gray-600 border-gray-200"
  defp type_color("email"), do: "bg-sky-50 text-sky-600 border-sky-100"
  defp type_color("phone"), do: "bg-emerald-50 text-emerald-600 border-emerald-100"
  defp type_color("formula"), do: "bg-yellow-50 text-yellow-600 border-yellow-100"
  defp type_color(_), do: "bg-gray-50 text-gray-600 border-gray-100"

  def render(assigns) do
    ~H"""
    <form phx-submit="save" class="max-w-4xl mx-auto">

      <%!-- Header --%>
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <a href={~p"/digisters/superadmin/registers"}
            class="p-2 rounded-lg text-gray-500 hover:text-gray-700 hover:bg-gray-100 transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </a>
          <h1 class="text-2xl font-bold text-gray-900">Create Register</h1>
        </div>
        <button type="submit"
          class="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
          Save
        </button>
      </div>

      <%!-- Basic Information --%>
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-5">
        <h2 class="text-sm font-semibold text-gray-900 mb-4">Basic Information</h2>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Name</label>
            <input type="text" name="name"
              placeholder="Register name"
              class={[
                "w-full border rounded-lg px-3.5 py-2.5 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent transition",
                if(@errors[:name], do: "border-red-400 focus:ring-red-300", else: "border-gray-200 focus:ring-gray-900")
              ]} />
            <p :if={@errors[:name]} class="mt-1.5 text-xs text-red-500">{@errors[:name]}</p>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
            <input type="text" name="description"
              placeholder="Brief description"
              class="w-full border border-gray-200 rounded-lg px-3.5 py-2.5 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
          </div>
        </div>
        <%= if @orgs != [] do %>
          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Company</label>
            <select name="organisation_id"
              class="w-full border border-gray-200 rounded-lg px-3.5 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition max-w-xs">
              <option value="">Select company (optional)</option>
              <option :for={org <- @orgs} value={org.id}>{org.name}</option>
            </select>
          </div>
        <% end %>
      </div>

      <%!-- Fields --%>
      <div class="bg-white rounded-xl border border-gray-200 p-6">

        <%!-- Fields header --%>
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-sm font-semibold text-gray-900">Fields</h2>
          <div class="flex items-center gap-1.5">
            <button type="button" phx-click="add_field" phx-value-type="text"
              class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Text
            </button>
            <button type="button" phx-click="add_field" phx-value-type="number"
              class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
              </svg>
              Number
            </button>
            <button type="button" phx-click="add_field" phx-value-type="currency"
              class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Currency
            </button>
            <button type="button" phx-click="add_field" phx-value-type="date"
              class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Date
            </button>
            <button type="button" phx-click="add_field" phx-value-type="select"
              class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
              Dropdown
            </button>
          </div>
        </div>

        <%!-- Fields area --%>
        <div class="rounded-xl border-2 border-dashed border-gray-200 bg-gray-50/40 min-h-[220px] p-4">
          <%= if @fields == [] do %>
            <div class="flex flex-col items-center justify-center h-40 gap-3">
              <button type="button" phx-click="add_field" phx-value-type="text"
                class="w-14 h-14 rounded-full bg-gray-100/80 hover:bg-gray-200 flex items-center justify-center transition-colors border border-gray-200">
                <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                </svg>
              </button>
              <p class="text-sm text-gray-400 font-medium">No fields added yet</p>
            </div>
          <% else %>
            <div class="space-y-2">
              <div :for={field <- @fields}
                class="flex items-center gap-3 bg-white rounded-lg border border-gray-200 px-4 py-3 group">
                <svg class="w-4 h-4 text-gray-300 flex-shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 8h16M4 16h16" />
                </svg>
                <span class={["px-2 py-0.5 rounded border text-xs font-semibold flex-shrink-0", type_color(field.type)]}>
                  {type_label(field.type)}
                </span>
                <input type="text" name={"label_#{field.id}"} value={field.label}
                  placeholder="Field label"
                  class="flex-1 text-sm text-gray-900 bg-transparent border-0 focus:outline-none focus:ring-0 placeholder-gray-400 min-w-0" />
                <button type="button"
                  phx-click="toggle_required" phx-value-id={field.id}
                  class={[
                    "text-xs px-2 py-1 rounded border transition-colors flex-shrink-0 font-medium",
                    if(field.required,
                      do: "border-indigo-300 bg-indigo-50 text-indigo-600",
                      else: "border-gray-200 text-gray-400 hover:border-gray-300 hover:text-gray-500")
                  ]}>
                  Required
                </button>
                <button type="button"
                  phx-click="remove_field" phx-value-id={field.id}
                  class="text-gray-300 hover:text-red-400 transition-colors flex-shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Add field buttons --%>
        <div class="mt-4 space-y-2">
          <div class="flex flex-wrap gap-2">
            <button type="button" phx-click="add_field" phx-value-type="text"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-blue-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Add Text
            </button>
            <button type="button" phx-click="add_field" phx-value-type="number"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-purple-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
              </svg>
              Add Number
            </button>
            <button type="button" phx-click="add_field" phx-value-type="currency"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-green-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Add Currency
            </button>
            <button type="button" phx-click="add_field" phx-value-type="date"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-orange-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              Add Date
            </button>
            <button type="button" phx-click="add_field" phx-value-type="select"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-indigo-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
              Add Dropdown
            </button>
            <button type="button" phx-click="add_field" phx-value-type="checkbox"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-pink-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Add Checkbox
            </button>
          </div>
          <div class="flex flex-wrap gap-2">
            <button type="button" phx-click="add_field" phx-value-type="long_text"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h8" />
              </svg>
              Add Long Text
            </button>
            <button type="button" phx-click="add_field" phx-value-type="email"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-sky-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              Add Email
            </button>
            <button type="button" phx-click="add_field" phx-value-type="phone"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-emerald-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.948V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
              </svg>
              Add Phone
            </button>
            <button type="button" phx-click="add_field" phx-value-type="formula"
              class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-gray-200 text-xs font-medium text-gray-600 hover:bg-gray-50 transition-colors">
              <svg class="w-3.5 h-3.5 text-yellow-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
              </svg>
              Add Formula
            </button>
          </div>
        </div>

      </div>

    </form>
    """
  end
end
