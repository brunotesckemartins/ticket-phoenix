defmodule TicketElixirWeb.TicketLive.New do
  use TicketElixirWeb, :live_view
  alias TicketElixir.Tickets
  alias TicketElixir.Tickets.Ticket

  @impl true
  def mount(_params, _session, socket) do
    changeset = Tickets.change_ticket(%Ticket{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"ticket" => params}, socket) do
    user = socket.assigns.current_scope.user
    params = Map.put(params, "solicitante_id", user.id)

    case Tickets.create_ticket(params) do
      {:ok, ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Chamado criado com sucesso!")
         |> push_navigate(to: ~p"/chamados/#{ticket.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-lg mx-auto p-4">
        <h1 class="text-2xl font-bold mb-4">Abrir Novo Chamado</h1>

        <.form for={@form} id="ticket-form" phx-submit="save" class="space-y-4">
          <.input field={@form[:subject]} type="text" label="Assunto" required />
          <.input field={@form[:description]} type="textarea" label="Descrição do problema" required />

          <.button class="btn btn-primary w-full">Criar Chamado</.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
