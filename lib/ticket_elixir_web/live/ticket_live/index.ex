defmodule TicketElixirWeb.TicketLive.Index do
  use TicketElixirWeb, :live_view
  alias TicketElixir.Tickets

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    tickets =
      if user.role == :suporte do
        Tickets.list_all_tickets()
      else
        Tickets.list_tickets_for_user(user.id)
      end

    {:ok, assign(socket, tickets: tickets)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto p-4">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-bold">Meus Chamados</h1>
          <.link navigate={~p"/chamados/novo"} class="btn btn-primary">Novo Chamado</.link>
        </div>

        <div class="space-y-4">
          <%= for ticket <- @tickets do %>
            <div class="card bg-base-100 shadow-xl border border-base-300">
              <div class="card-body">
                <h2 class="card-title">
                  <.link navigate={~p"/chamados/#{ticket.id}"} class="hover:underline">
                    {ticket.subject}
                  </.link>
                </h2>
                <p class="text-sm text-gray-500">Status: <strong>{ticket.status}</strong></p>
                <p class="text-sm text-gray-500">Aberto em: {Calendar.strftime(ticket.inserted_at, "%d/%m/%Y às %H:%M")}</p>
              </div>
            </div>
          <% end %>
          <div :if={@tickets == []} class="text-center text-gray-500 py-10">
            Nenhum chamado encontrado.
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
