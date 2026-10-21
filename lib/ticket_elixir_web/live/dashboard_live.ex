defmodule TicketElixirWeb.DashboardLive do
  use TicketElixirWeb, :live_view
  alias TicketElixir.Tickets

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Busca as estatísticas no banco
    stats = %{
      abertos: Tickets.count_tickets(user, :aberto),
      em_andamento: Tickets.count_tickets(user, :em_andamento),
      resolvidos: Tickets.count_tickets(user, :resolvido)
    }

    {:ok, assign(socket, stats: stats, user_role: user.role)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto p-4 space-y-8">

        <div class="text-center md:text-left">
          <h1 class="text-3xl font-bold">Olá, {@current_scope.user.name}!</h1>
          <p class="text-base-content/70 mt-1">
            <%= if @user_role == :suporte do %>
              Aqui está o resumo do suporte hoje.
            <% else %>
              Aqui está o resumo dos seus atendimentos.
            <% end %>
          </p>
        </div>

        <!-- Cards de Estatísticas (Usando o componente Stat do DaisyUI) -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">

          <!-- Card Abertos -->
          <div class="stats shadow border border-base-300 bg-base-100">
            <div class="stat">
              <div class="stat-figure text-warning">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
              </div>
              <div class="stat-title">Aguardando Atendimento</div>
              <div class="stat-value text-warning">{@stats.abertos}</div>
              <div class="stat-desc">Chamados abertos</div>
            </div>
          </div>

          <!-- Card Em Andamento -->
          <div class="stats shadow border border-base-300 bg-base-100">
            <div class="stat">
              <div class="stat-figure text-primary">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
              </div>
              <div class="stat-title">Em Andamento</div>
              <div class="stat-value text-primary">{@stats.em_andamento}</div>
              <div class="stat-desc">Sendo atendidos agora</div>
            </div>
          </div>

          <!-- Card Resolvidos -->
          <div class="stats shadow border border-base-300 bg-base-100">
            <div class="stat">
              <div class="stat-figure text-success">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              </div>
              <div class="stat-title">Resolvidos</div>
              <div class="stat-value text-success">{@stats.resolvidos}</div>
              <div class="stat-desc">Concluídos</div>
            </div>
          </div>

        </div>

        <!-- Ações Rápidas -->
        <div class="flex flex-col sm:flex-row gap-4 mt-8">
          <.link navigate={~p"/chamados/novo"} class="btn btn-primary btn-lg flex-1">
            + Abrir Novo Chamado
          </.link>
          <.link navigate={~p"/chamados"} class="btn btn-outline btn-lg flex-1">
            Ver Todos os Chamados
          </.link>
        </div>

      </div>
    </Layouts.app>
    """
  end
end
