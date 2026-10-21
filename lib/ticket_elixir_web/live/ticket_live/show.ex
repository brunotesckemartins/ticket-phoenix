defmodule TicketElixirWeb.TicketLive.Show do
  use TicketElixirWeb, :live_view

  alias TicketElixir.{Tickets, Messages}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    ticket = Tickets.get_ticket_with_messages!(id)
    user = socket.assigns.current_scope.user

    if user.role == :solicitante and ticket.solicitante_id != user.id do
      {:ok, push_navigate(socket, to: ~p"/chamados")}
    else
      if connected?(socket) do
        Messages.subscribe(ticket.id)
        Tickets.subscribe_ticket(ticket.id)
      end

      {:ok,
       socket
       |> assign(:ticket, ticket)
       |> assign(:messages, ticket.messages)
       |> assign(:form, to_form(%{"body" => "", "internal" => false}))}
    end
  end

  @impl true
  def handle_event("send_message", params, socket) do
    body = params["body"]
    internal = params["internal"] == "true" and socket.assigns.current_scope.user.role == :suporte
    user = socket.assigns.current_scope.user
    ticket = socket.assigns.ticket

    if String.trim(body) == "" do
      {:noreply, socket}
    else
      Messages.create_message(%{
        body: body,
        internal: internal,
        ticket_id: ticket.id,
        user_id: user.id
      })

      # Lógica de reabertura
      ticket =
        if user.role == :solicitante and ticket.status in [:resolvido, :fechado] and not internal do
          {:ok, t} = Tickets.update_ticket(ticket, %{status: :em_andamento})
          t
        else
          ticket
        end

      {:noreply,
       socket
       |> assign(:ticket, ticket)
       |> assign(:form, to_form(%{"body" => "", "internal" => false}))}
    end
  end

  def handle_event("assign_ticket", _params, socket) do
    user = socket.assigns.current_scope.user
    ticket = socket.assigns.ticket

    if user.role == :suporte and ticket.status == :aberto do
      {:ok, updated_ticket} = Tickets.update_ticket(ticket, %{atendente_id: user.id, status: :em_andamento})
      {:noreply, assign(socket, :ticket, updated_ticket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("resolve_ticket", _params, socket) do
    user = socket.assigns.current_scope.user
    ticket = socket.assigns.ticket

    if user.role == :suporte do
      {:ok, updated_ticket} = Tickets.update_ticket(ticket, %{status: :resolvido})
      {:noreply, assign(socket, :ticket, updated_ticket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    user = socket.assigns.current_scope.user
    if message.internal and user.role == :solicitante do
      {:noreply, socket}
    else
      {:noreply, update(socket, :messages, fn msgs -> msgs ++ [message] end)}
    end
  end

  @impl true
  def handle_info({:ticket_updated, ticket}, socket) do
    {:noreply, assign(socket, :ticket, ticket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto p-4 flex flex-col h-[80vh]">

        <div class="border-b pb-4 mb-4 flex justify-between items-center">
          <div>
            <h1 class="text-2xl font-bold">{@ticket.subject}</h1>
            <p class="text-sm text-gray-500">
              Solicitante: {@ticket.solicitante.name} | Status: <strong class="uppercase text-primary">{@ticket.status}</strong>
              <%= if @ticket.atendente do %>
                | Atendente: <strong>{@ticket.atendente.name}</strong>
              <% end %>
            </p>
          </div>
          <div class="flex gap-2">
            <%= if @current_scope.user.role == :suporte do %>
              <button :if={@ticket.status == :aberto} phx-click="assign_ticket" class="btn btn-warning btn-sm">Assumir Chamado</button>
              <button :if={@ticket.status == :em_andamento} phx-click="resolve_ticket" class="btn btn-success btn-sm">Marcar como Resolvido</button>
            <% end %>
            <.link navigate={~p"/chamados"} class="btn btn-sm">Voltar</.link>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto space-y-4 p-4 bg-base-200 rounded-lg" id="chat-container" phx-hook="ScrollToBottom">
          <%= for msg <- @messages do %>
            <div class={"chat " <> if msg.user_id == @current_scope.user.id, do: "chat-end", else: "chat-start"}>
              <div class="chat-header text-xs opacity-50 mb-1">
                {msg.user.name} - {Calendar.strftime(msg.inserted_at, "%d/%m %H:%M")}
                <span :if={msg.internal} class="badge badge-warning badge-sm ml-2">Nota Interna</span>
              </div>
              <div class={"chat-bubble " <> if msg.internal, do: "chat-bubble-warning", else: (if msg.user_id == @current_scope.user.id, do: "chat-bubble-primary", else: "")}>
                {msg.body}
              </div>
            </div>
          <% end %>
        </div>

        <div class="mt-4">
          <.form for={@form} id="chat-form" phx-submit="send_message" class="flex flex-col gap-2">
            <div class="flex gap-2">
              <.input field={@form[:body]} type="text" placeholder="Digite sua mensagem..." autocomplete="off" class="flex-1 input input-bordered w-full" />
              <.button type="submit" class="btn btn-primary">Enviar</.button>
            </div>
            <%= if @current_scope.user.role == :suporte do %>
              <label class="label cursor-pointer justify-start gap-2 w-fit">
                <.input field={@form[:internal]} type="checkbox" label="Nota Interna (Solicitante não vê)" class="checkbox checkbox-warning checkbox-sm" />
              </label>
            <% end %>
          </.form>
        </div>

      </div>
    </Layouts.app>
    """
  end
end
