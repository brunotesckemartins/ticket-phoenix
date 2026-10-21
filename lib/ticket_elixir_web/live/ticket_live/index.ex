defmodule TicketElixirWeb.TicketLive.Index do
  use TicketElixirWeb, :live_view
  alias TicketElixir.Tickets

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Tickets.subscribe_all_tickets()

    user = socket.assigns.current_scope.user
    # Inicializa com filtros vazios
    tickets = Tickets.list_tickets_with_unread(user, %{})

    {:ok, assign(socket, tickets: tickets, current_filter: "", search: "")}
  end

  @impl true
  def handle_info({:new_ticket_message, _ticket_id}, socket) do
    user = socket.assigns.current_scope.user
    # Mantém os filtros atuais ao recarregar em tempo real
    params = %{"status" => socket.assigns.current_filter, "search" => socket.assigns.search}
    tickets = Tickets.list_tickets_with_unread(user, params)

    {:noreply, assign(socket, tickets: tickets)}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    user = socket.assigns.current_scope.user
    params = %{"status" => status, "search" => socket.assigns.search}
    tickets = Tickets.list_tickets_with_unread(user, params)

    {:noreply, assign(socket, tickets: tickets, current_filter: status)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    user = socket.assigns.current_scope.user
    params = %{"status" => socket.assigns.current_filter, "search" => search}
    tickets = Tickets.list_tickets_with_unread(user, params)

    {:noreply, assign(socket, tickets: tickets, search: search)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto p-4">

        <!-- Cabeçalho: Título e Botão (Empilha no celular, lado a lado no PC) -->
        <div class="flex flex-col sm:flex-row justify-between sm:items-center gap-4 mb-6">
          <h1 class="text-2xl font-bold">Meus Chamados</h1>
          <.link navigate={~p"/chamados/novo"} class="btn btn-primary w-full sm:w-auto">
            Novo Chamado
          </.link>
        </div>

        <!-- Barra de Busca e Filtros -->
        <div class="flex flex-col gap-3 mb-6">
          <form phx-change="search" class="w-full">
            <input
              type="text"
              name="search"
              value={@search}
              placeholder="Buscar por assunto..."
              class="input input-bordered w-full"
              phx-debounce="300"
            />
          </form>

          <!-- No celular, os botões rolam para o lado. No desktop, quebram linha normalmente -->
          <div class="flex gap-2 overflow-x-auto pb-2 sm:pb-0 sm:flex-wrap">
            <button phx-click="filter" phx-value-status="" class={"btn btn-sm whitespace-nowrap " <> if @current_filter == "", do: "btn-active", else: ""}>Todos</button>
            <button phx-click="filter" phx-value-status="aberto" class={"btn btn-sm whitespace-nowrap " <> if @current_filter == "aberto", do: "btn-active", else: ""}>Abertos</button>
            <button phx-click="filter" phx-value-status="em_andamento" class={"btn btn-sm whitespace-nowrap " <> if @current_filter == "em_andamento", do: "btn-active", else: ""}>Em Andamento</button>
            <button phx-click="filter" phx-value-status="resolvido" class={"btn btn-sm whitespace-nowrap " <> if @current_filter == "resolvido", do: "btn-active", else: ""}>Resolvidos</button>
          </div>
        </div>

        <div class="space-y-4">
          <%= for {ticket, unread_count} <- @tickets do %>
            <div class="card bg-base-100 shadow-md border border-base-300 hover:shadow-lg transition-shadow">
              <div class="card-body p-4 sm:p-6">
                <!-- Título e Badge de novas mensagens -->
                <h2 class="card-title flex flex-wrap items-center gap-2">
                  <.link navigate={~p"/chamados/#{ticket.id}"} class="hover:underline hover:text-primary">
                    {ticket.subject}
                  </.link>
                  <span :if={unread_count > 0} class="badge badge-error text-white font-bold badge-sm">
                    {unread_count} nova(s)
                  </span>
                </h2>

                <!-- Informações do Chamado (Empilha no celular, lado a lado no PC) -->
                <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 mt-2 text-sm text-base-content/70">
                  <p>Status: <strong class="uppercase">{ticket.status}</strong></p>
                  <p class="hidden sm:block">•</p>
                  <p>Atualizado em: {Calendar.strftime(ticket.updated_at, "%d/%m/%Y às %H:%M")}</p>
                </div>
              </div>
            </div>
          <% end %>

          <div :if={@tickets == []} class="text-center text-base-content/50 py-10 bg-base-100 rounded-lg border border-dashed border-base-300">
            Nenhum chamado encontrado com esses filtros.
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
