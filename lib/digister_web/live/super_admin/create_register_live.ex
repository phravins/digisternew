defmodule DigisterWeb.SuperAdmin.CreateRegisterLive do
  use DigisterWeb, :live_view

  alias Digister.Registers
  alias Digister.Organisations
  alias Digister.Activities

  on_mount {DigisterWeb.SuperAdminAuth, :require_super_admin}

  def mount(params, _session, socket) do
    orgs = Organisations.list_organisations()

    socket =
      socket
      |> assign(:active_nav, :new_register)
      |> assign(:orgs, orgs)
      |> assign(:errors, %{})

    socket =
      case socket.assigns.live_action do
        :edit ->
          register = Registers.get_register!(params["register_id"])
          fields = Registers.list_fields(register.id)
          built = Enum.with_index(fields) |> Enum.map(fn {f, i} -> build_field(f, i) end)

          socket
          |> assign(:page_title, "Edit Register")
          |> assign(:register, register)
          |> assign(:name, register.name || "")
          |> assign(:description, register.description || "")
          |> assign(:organisation_id, to_string(register.organisation_id || ""))
          |> assign(:fields, built)
          |> assign(:next_id, length(built))

        _ ->
          socket
          |> assign(:page_title, "Create Register")
          |> assign(:register, nil)
          |> assign(:name, "")
          |> assign(:description, "")
          |> assign(:organisation_id, "")
          |> assign(:fields, [])
          |> assign(:next_id, 0)
      end

    {:ok, socket}
  end

  # Rebuilds the in-form field map (with atom-keyed config) from a stored RegisterField.
  defp build_field(field, index) do
    config =
      case field.field_type do
        t when t in ["dropdown", "multi_select", "checkbox"] -> %{options: field.options || []}
        "currency" -> %{currency: List.first(field.options || []) || "INR"}
        "phone" -> %{dial_code: List.first(field.options || []) || "+91"}
        "file" -> %{allowed: field.options || []}
        _ -> %{}
      end

    %{id: index, label: field.label, type: field.field_type, required: field.required, config: config}
  end

  def handle_event("form_change", params, socket) do
    {:noreply,
     socket
     |> assign(:name, params["name"] || socket.assigns.name)
     |> assign(:description, params["description"] || socket.assigns.description)
     |> assign(:organisation_id, params["organisation_id"] || socket.assigns.organisation_id)}
  end

  def handle_event("add_field", %{"type" => type}, socket) do
    new_field = %{
      id: socket.assigns.next_id,
      label: "",
      type: type,
      required: false,
      config: default_config(type)
    }

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

  def handle_event("update_label", %{"id" => id_str, "value" => val}, socket) do
    id = String.to_integer(id_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id, do: %{f | label: val}, else: f
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("reorder_fields", %{"order" => order}, socket) do
    by_id = Map.new(socket.assigns.fields, &{to_string(&1.id), &1})
    fields = order |> Enum.map(&Map.get(by_id, &1)) |> Enum.reject(&is_nil/1)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("update_config", %{"id" => id_str, "key" => key, "value" => val}, socket) do
    id = String.to_integer(id_str)
    atom_key = case key do
      "currency" -> :currency
      "dial_code" -> :dial_code
      other -> String.to_atom(other)
    end
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id do
        %{f | config: Map.put(f.config, atom_key, val)}
      else
        f
      end
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("add_option", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id do
        opts = Map.get(f.config, :options, [])
        %{f | config: Map.put(f.config, :options, opts ++ [""])}
      else
        f
      end
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("update_option", %{"id" => id_str, "index" => idx_str, "value" => val}, socket) do
    id = String.to_integer(id_str)
    idx = String.to_integer(idx_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id do
        opts = f.config.options |> List.replace_at(idx, val)
        %{f | config: Map.put(f.config, :options, opts)}
      else
        f
      end
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("remove_option", %{"id" => id_str, "index" => idx_str}, socket) do
    id = String.to_integer(id_str)
    idx = String.to_integer(idx_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id do
        opts = List.delete_at(f.config.options, idx)
        %{f | config: Map.put(f.config, :options, opts)}
      else
        f
      end
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("toggle_file_type", %{"id" => id_str, "type" => ftype}, socket) do
    id = String.to_integer(id_str)
    fields = Enum.map(socket.assigns.fields, fn f ->
      if f.id == id do
        allowed = f.config.allowed
        new_allowed =
          if ftype in allowed,
            do: List.delete(allowed, ftype),
            else: allowed ++ [ftype]
        %{f | config: Map.put(f.config, :allowed, new_allowed)}
      else
        f
      end
    end)
    {:noreply, assign(socket, :fields, fields)}
  end

  def handle_event("save", params, socket) do
    name = String.trim(params["name"] || "")
    desc = params["description"] || ""
    org_id = params["organisation_id"] || ""
    is_template = params["is_template"] == "true"

    errors =
      %{}
      |> then(fn e -> if name == "", do: Map.put(e, :name, "Register name is required."), else: e end)

    if errors == %{} do
      attrs = %{
        name: name,
        description: if(String.trim(desc) == "", do: nil, else: String.trim(desc)),
        organisation_id: if(is_template || String.trim(org_id) == "", do: nil, else: org_id),
        is_template: is_template
      }

      editing = socket.assigns.register

      result =
        if editing do
          Registers.update_register(editing, attrs)
        else
          Registers.create_register(attrs)
        end

      case result do
        {:ok, register} ->
          if editing, do: Registers.delete_fields(register.id)

          socket.assigns.fields
          |> Enum.with_index()
          |> Enum.each(fn {field, index} ->
            label = String.trim(params["label_#{field.id}"] || "")
            effective_label = if label == "", do: type_label(field.type), else: label

            options = case field.type do
              t when t in ["dropdown", "multi_select", "checkbox"] ->
                Enum.reject(field.config.options, &(String.trim(&1) == ""))
              "currency" -> [field.config[:currency] || "INR"]
              "phone" -> [field.config[:dial_code] || "+91"]
              "file" -> field.config[:allowed] || []
              _ -> nil
            end

            Registers.create_field(%{
              register_id: register.id,
              label: effective_label,
              field_key: slugify(effective_label) <> "_#{field.id}",
              field_type: field.type,
              required: field.required,
              position: index,
              options: options
            })
          end)

          user = socket.assigns.current_scope.user
          actor = user.username || String.split(user.email, "@") |> List.first()

          action =
            cond do
              editing && is_template -> "updated template \"#{name}\""
              editing -> "updated register \"#{name}\""
              is_template -> "created template \"#{name}\""
              true -> "created register \"#{name}\""
            end

          Activities.log(%{user_name: actor, action: action})

          redirect_to =
            cond do
              is_template -> ~p"/digisters/superadmin/templates"
              register.organisation_id -> ~p"/digisters/superadmin/registers/#{register.organisation_id}"
              true -> ~p"/digisters/superadmin/registers"
            end

          msg =
            cond do
              editing && is_template -> "Template \"#{name}\" updated successfully."
              editing -> "Register \"#{name}\" updated successfully."
              is_template -> "Template \"#{name}\" saved successfully."
              true -> "Register \"#{name}\" created successfully."
            end

          {:noreply,
           socket
           |> put_flash(:info, msg)
           |> push_navigate(to: redirect_to)}

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

  defp default_config("dropdown"), do: %{options: []}
  defp default_config("multi_select"), do: %{options: []}
  defp default_config("checkbox"), do: %{options: []}
  defp default_config("currency"), do: %{currency: "INR"}
  defp default_config("phone"), do: %{dial_code: "+91"}
  defp default_config("file"), do: %{allowed: ["PDF", "JPG", "JPEG", "DOCX", "XLSX", "XML", "HTML"]}
  defp default_config(_), do: %{}

  defp type_label("text"), do: "Text"
  defp type_label("long_text"), do: "Long Text"
  defp type_label("number"), do: "Number"
  defp type_label("decimal"), do: "Decimal"
  defp type_label("currency"), do: "Currency"
  defp type_label("email"), do: "Email"
  defp type_label("reference_no"), do: "Reference No"
  defp type_label("url"), do: "URL"
  defp type_label("date"), do: "Date"
  defp type_label("datetime"), do: "Date & Time"
  defp type_label("checkbox"), do: "Checkbox"
  defp type_label("multi_select"), do: "Multi Select"
  defp type_label("dropdown"), do: "Dropdown"
  defp type_label("phone"), do: "Phone Number"
  defp type_label("time"), do: "Time"
  defp type_label("file"), do: "File Upload"
  defp type_label(t), do: String.capitalize(t)

  defp type_color("text"), do: "bg-blue-50 text-blue-600 border-blue-100"
  defp type_color("long_text"), do: "bg-gray-100 text-gray-600 border-gray-200"
  defp type_color("number"), do: "bg-purple-50 text-purple-600 border-purple-100"
  defp type_color("decimal"), do: "bg-violet-50 text-violet-600 border-violet-100"
  defp type_color("currency"), do: "bg-green-50 text-green-600 border-green-100"
  defp type_color("email"), do: "bg-sky-50 text-sky-600 border-sky-100"
  defp type_color("reference_no"), do: "bg-amber-50 text-amber-600 border-amber-100"
  defp type_color("url"), do: "bg-cyan-50 text-cyan-600 border-cyan-100"
  defp type_color("date"), do: "bg-orange-50 text-orange-600 border-orange-100"
  defp type_color("datetime"), do: "bg-rose-50 text-rose-600 border-rose-100"
  defp type_color("checkbox"), do: "bg-pink-50 text-pink-600 border-pink-100"
  defp type_color("multi_select"), do: "bg-fuchsia-50 text-fuchsia-600 border-fuchsia-100"
  defp type_color("dropdown"), do: "bg-indigo-50 text-indigo-600 border-indigo-100"
  defp type_color("phone"), do: "bg-emerald-50 text-emerald-600 border-emerald-100"
  defp type_color("time"), do: "bg-teal-50 text-teal-600 border-teal-100"
  defp type_color("file"), do: "bg-slate-100 text-slate-600 border-slate-200"
  defp type_color(_), do: "bg-gray-50 text-gray-600 border-gray-100"

  defp type_hint("text"), do: "Max 100 characters · allows special characters"
  defp type_hint("long_text"), do: "Max 500 characters · allows special characters"
  defp type_hint("number"), do: "Whole numbers only (no decimals)"
  defp type_hint("decimal"), do: "Decimal numbers only (e.g. 12.50)"
  defp type_hint("email"), do: "Valid email address only"
  defp type_hint("reference_no"), do: "Alphanumeric + special chars (e.g. REF-09)"
  defp type_hint("url"), do: "Valid URL only (e.g. https://example.com)"
  defp type_hint("date"), do: "Date only"
  defp type_hint("datetime"), do: "Date + time with AM/PM"
  defp type_hint("time"), do: "Time only (HH:MM AM/PM)"
  defp type_hint(_), do: nil

  defp type_icon("text") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />|
  end
  defp type_icon("long_text") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h8" />|
  end
  defp type_icon("number") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />|
  end
  defp type_icon("decimal") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" /><circle cx="19" cy="19" r="1" fill="currentColor" />|
  end
  defp type_icon("currency") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />|
  end
  defp type_icon("email") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />|
  end
  defp type_icon("reference_no") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />|
  end
  defp type_icon("url") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />|
  end
  defp type_icon("date") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />|
  end
  defp type_icon("datetime") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /><path stroke-linecap="round" stroke-linejoin="round" d="M12 11v4l2 2" />|
  end
  defp type_icon("checkbox") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />|
  end
  defp type_icon("multi_select") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />|
  end
  defp type_icon("dropdown") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" />|
  end
  defp type_icon("phone") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.948V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />|
  end
  defp type_icon("time") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />|
  end
  defp type_icon("file") do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />|
  end
  defp type_icon(_) do
    ~s|<path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />|
  end

  defp type_icon_color("text"), do: "text-blue-500"
  defp type_icon_color("long_text"), do: "text-gray-400"
  defp type_icon_color("number"), do: "text-purple-500"
  defp type_icon_color("decimal"), do: "text-violet-500"
  defp type_icon_color("currency"), do: "text-green-500"
  defp type_icon_color("email"), do: "text-sky-500"
  defp type_icon_color("reference_no"), do: "text-amber-500"
  defp type_icon_color("url"), do: "text-cyan-500"
  defp type_icon_color("date"), do: "text-orange-500"
  defp type_icon_color("datetime"), do: "text-rose-500"
  defp type_icon_color("checkbox"), do: "text-pink-500"
  defp type_icon_color("multi_select"), do: "text-fuchsia-500"
  defp type_icon_color("dropdown"), do: "text-indigo-500"
  defp type_icon_color("phone"), do: "text-emerald-500"
  defp type_icon_color("time"), do: "text-teal-500"
  defp type_icon_color("file"), do: "text-slate-500"
  defp type_icon_color(_), do: "text-gray-400"

  @all_types [
    {"text", "Text"},
    {"long_text", "Long Text"},
    {"number", "Number"},
    {"decimal", "Decimal"},
    {"currency", "Currency"},
    {"email", "Email"},
    {"reference_no", "Reference No"},
    {"url", "URL"},
    {"date", "Date"},
    {"datetime", "Date & Time"},
    {"checkbox", "Checkbox"},
    {"multi_select", "Multi Select"},
    {"dropdown", "Dropdown"},
    {"phone", "Phone Number"},
    {"time", "Time"},
    {"file", "File Upload"}
  ]

  def render(assigns) do
    assigns = assign(assigns, :all_types, @all_types)

    ~H"""
    <form phx-submit="save" phx-change="form_change" class="flex-1 flex flex-col min-h-0 w-full">

      <%!-- Header --%>
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
          <a href={~p"/digisters/superadmin/registers"}
            class="p-2 rounded-lg text-gray-500 hover:text-gray-700 hover:bg-gray-100 transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </a>
          <h1 class="text-2xl font-bold text-gray-900">{if @register, do: "Edit Register", else: "Create Register"}</h1>
        </div>
        <div class="flex items-center gap-2">
          <button type="submit" name="is_template" value="true"
            class="flex items-center gap-2 bg-white hover:bg-gray-50 text-gray-700 border border-gray-300 px-4 py-2.5 rounded-lg text-sm font-semibold transition-colors">
            <svg class="w-4 h-4 text-purple-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
            </svg>
            Save as Template
          </button>
          <button type="submit"
            class="flex items-center gap-2 bg-gray-900 hover:bg-gray-700 text-white px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
            </svg>
            Save
          </button>
        </div>
      </div>

      <%!-- Basic Information --%>
      <div class="bg-white rounded-xl border border-gray-200 p-5 mb-4">
        <h2 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Basic Information</h2>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Name</label>
            <input type="text" name="name" value={@name}
              placeholder="Register name"
              class={[
                "w-full border rounded-lg px-3.5 py-2.5 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:border-transparent transition",
                if(@errors[:name], do: "border-red-400 focus:ring-red-300", else: "border-gray-200 focus:ring-blue-500")
              ]} />
            <p :if={@errors[:name]} class="mt-1.5 text-xs text-red-500">{@errors[:name]}</p>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
            <input type="text" name="description" value={@description}
              placeholder="Brief description"
              class="w-full border border-gray-200 rounded-lg px-3.5 py-2.5 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition" />
          </div>
        </div>
        <%= if @orgs != [] do %>
          <div class="mt-3">
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Company</label>
            <select name="organisation_id"
              class="border border-gray-200 rounded-lg px-3.5 py-2.5 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition max-w-xs">
              <option value="">Select company (optional)</option>
              <option :for={org <- @orgs} value={org.id}
                selected={@organisation_id == to_string(org.id)}>{org.name}</option>
            </select>
          </div>
        <% end %>
      </div>

      <%!-- Fields builder: left panel + right panel --%>
      <div class="bg-white rounded-xl border border-gray-200 flex-1 flex min-h-0 overflow-hidden">

        <%!-- Left: field type picker --%>
        <div class="w-44 flex-shrink-0 border-r border-gray-100 bg-gray-50/60 flex flex-col">
          <div class="px-4 py-3 border-b border-gray-100">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Field Types</p>
          </div>
          <div class="flex-1 overflow-y-auto py-2 px-2 space-y-0.5">
            <button :for={{type, label} <- @all_types}
              type="button"
              phx-click="add_field"
              phx-value-type={type}
              class="w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm font-medium text-gray-600 hover:bg-white hover:shadow-sm hover:text-gray-900 transition-all text-left">
              <svg class={["w-4 h-4 flex-shrink-0", type_icon_color(type)]} fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                {Phoenix.HTML.raw(type_icon(type))}
              </svg>
              {label}
            </button>
          </div>
        </div>

        <%!-- Right: field list --%>
        <div class="flex-1 flex flex-col min-w-0">
          <div class="px-6 py-3 border-b border-gray-100 flex items-center gap-2">
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Fields</p>
            <span class="text-xs text-gray-400">({length(@fields)} added)</span>
          </div>

          <%= if @fields == [] do %>
            <div class="flex-1 flex flex-col items-center justify-center gap-2 text-center px-8">
              <svg class="w-10 h-10 text-gray-200" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p class="text-sm font-medium text-gray-400">No fields yet</p>
              <p class="text-xs text-gray-300">Pick a field type from the left panel to add it.</p>
            </div>
          <% else %>
            <div id="fields-list" phx-hook="Sortable" class="flex-1 overflow-y-auto p-4 space-y-2">
              <div :for={field <- @fields}
                id={"field-#{field.id}"}
                data-id={field.id}
                class="bg-gray-50 rounded-lg border border-gray-200 overflow-hidden">

                <%!-- Field row top: handle + badge + label + delete --%>
                <div class="flex items-center gap-3 px-4 py-3">
                  <svg data-drag-handle class="w-4 h-4 text-gray-300 flex-shrink-0 cursor-grab active:cursor-grabbing" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 8h16M4 16h16" />
                  </svg>
                  <span class={["px-2 py-0.5 rounded border text-xs font-semibold flex-shrink-0 whitespace-nowrap", type_color(field.type)]}>
                    {type_label(field.type)}
                  </span>
                  <input type="text" name={"label_#{field.id}"} value={field.label}
                    placeholder="Field label"
                    phx-blur="update_label" phx-value-id={field.id}
                    class="flex-1 text-sm text-gray-900 bg-transparent border-0 focus:outline-none focus:ring-0 placeholder-gray-400 min-w-0" />
                  <button type="button"
                    phx-click="remove_field" phx-value-id={field.id}
                    class="text-gray-400 hover:text-red-500 transition-colors flex-shrink-0 p-0.5">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <%!-- Field type-specific config --%>

                <%!-- Hint text for simple types --%>
                <%= if type_hint(field.type) do %>
                  <div class="px-4 pb-2.5 flex items-center gap-1.5">
                    <svg class="w-3 h-3 text-gray-300 flex-shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <p class="text-xs text-gray-400">{type_hint(field.type)}</p>
                  </div>
                <% end %>

                <%!-- Currency selector --%>
                <%= if field.type == "currency" do %>
                  <div class="px-4 pb-3">
                    <p class="text-xs text-gray-500 font-medium mb-1.5">Currency:</p>
                    <div class="flex flex-wrap gap-1.5">
                      <%= for {val, label} <- [{"INR","₹ INR"},{"USD","$ USD"},{"EUR","€ EUR"},{"GBP","£ GBP"},{"JPY","¥ JPY"}] do %>
                        <button type="button"
                          phx-click="update_config"
                          phx-value-id={field.id}
                          phx-value-key="currency"
                          phx-value-value={val}
                          class={[
                            "px-2.5 py-1 rounded-md text-xs font-medium border transition-colors",
                            if((field.config[:currency] || "INR") == val,
                              do: "bg-green-50 border-green-400 text-green-700",
                              else: "bg-white border-gray-200 text-gray-500 hover:border-gray-300")
                          ]}>
                          {label}
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%!-- Phone dial code selector --%>
                <%= if field.type == "phone" do %>
                  <div class="px-4 pb-3">
                    <p class="text-xs text-gray-500 font-medium mb-1.5">Dial code:</p>
                    <div class="flex flex-wrap gap-1.5">
                      <%= for {val, label} <- [{"+91","IN +91"},{"+1-US","US +1"},{"+44","UK +44"},{"+61","AU +61"},{"+1-CA","CA +1"}] do %>
                        <button type="button"
                          phx-click="update_config"
                          phx-value-id={field.id}
                          phx-value-key="dial_code"
                          phx-value-value={val}
                          class={[
                            "px-2.5 py-1 rounded-md text-xs font-medium border transition-colors",
                            if((field.config[:dial_code] || "+91") == val,
                              do: "bg-emerald-50 border-emerald-400 text-emerald-700",
                              else: "bg-white border-gray-200 text-gray-500 hover:border-gray-300")
                          ]}>
                          {label}
                        </button>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <%!-- Dropdown / Multi Select / Checkbox option builder --%>
                <%= if field.type in ["dropdown", "multi_select", "checkbox"] do %>
                  <div class="px-4 pb-3 space-y-1.5">
                    <p class="text-xs text-gray-500 font-medium">Options:</p>
                    <%= if field.config.options == [] do %>
                      <p class="text-xs text-gray-300 italic">No options yet — add one below.</p>
                    <% else %>
                      <div class="space-y-1">
                        <div :for={{opt, idx} <- Enum.with_index(field.config.options)}
                          class="flex items-center gap-1.5">
                          <input type="text"
                            value={opt}
                            placeholder={"Option #{idx + 1}"}
                            phx-blur="update_option"
                            phx-value-id={field.id}
                            phx-value-index={idx}
                            class="flex-1 text-xs border border-gray-200 rounded px-2 py-1 focus:outline-none focus:ring-1 focus:ring-blue-400 bg-white" />
                          <button type="button"
                            phx-click="remove_option"
                            phx-value-id={field.id}
                            phx-value-index={idx}
                            class="text-gray-300 hover:text-red-400 transition-colors flex-shrink-0">
                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    <% end %>
                    <button type="button"
                      phx-click="add_option"
                      phx-value-id={field.id}
                      class="flex items-center gap-1 text-xs text-blue-500 hover:text-blue-700 font-medium transition-colors mt-1">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                      </svg>
                      Add option
                    </button>
                  </div>
                <% end %>

                <%!-- File Upload type toggles --%>
                <%= if field.type == "file" do %>
                  <div class="px-4 pb-3">
                    <p class="text-xs text-gray-500 font-medium mb-1.5">Allowed file types:</p>
                    <div class="flex flex-wrap gap-1.5">
                      <%= for ftype <- ["PDF", "JPG", "JPEG", "DOCX", "XLSX", "XML", "HTML"] do %>
                        <button type="button"
                          phx-click="toggle_file_type"
                          phx-value-id={field.id}
                          phx-value-type={ftype}
                          class={[
                            "px-2.5 py-1 rounded-md text-xs font-medium border transition-colors",
                            if(ftype in (field.config[:allowed] || []),
                              do: "bg-blue-50 border-blue-300 text-blue-600",
                              else: "bg-white border-gray-200 text-gray-400")
                          ]}>
                          {ftype}
                        </button>
                      <% end %>
                    </div>
                    <p class="text-xs text-gray-400 mt-1.5">
                      Only <%= Enum.join(field.config[:allowed] || [], ", ") %> files will be accepted
                    </p>
                  </div>
                <% end %>

              </div>
            </div>
          <% end %>
        </div>

      </div>

    </form>
    """
  end
end
