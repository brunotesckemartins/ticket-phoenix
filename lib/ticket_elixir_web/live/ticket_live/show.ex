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
      # MARCAR COMO LIDO AO ENTRAR
      Tickets.mark_as_read(ticket.id, user.id)

      if connected?(socket) do
        Messages.subscribe(ticket.id)
        Tickets.subscribe_ticket(ticket.id)
      end

      socket =
        socket
        |> assign(:ticket, ticket)
        |> assign(:messages, ticket.messages)
        |> assign(:form, to_form(%{"body" => "", "internal" => false}))
        |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .gif .mp4 .webm .mov), max_entries: 3, max_file_size: 50_000_000)

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_event("send_message", params, socket) do
    body = params["body"]
    internal = params["internal"] == "true" and socket.assigns.current_scope.user.role == :suporte
    user = socket.assigns.current_scope.user
    ticket = socket.assigns.ticket

    if String.trim(body) == "" and socket.assigns.uploads.image.entries == [] do
      {:noreply, socket}
    else
      # 1. Salva a mensagem no banco
      {:ok, message} = Messages.create_message(%{
        body: body,
        internal: internal,
        ticket_id: ticket.id,
        user_id: user.id
      })

      # 2. Salva os anexos
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        filename = "#{Ecto.UUID.generate()}#{Path.extname(entry.client_name)}"
        dest = Path.join(["priv/static/uploads", filename])

        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)

        Messages.create_attachment(%{
          message_id: message.id,
          filename: entry.client_name,
          content_type: entry.client_type,
          path: "/uploads/#{filename}"
        })

        {:ok, filename}
      end)

      # 3. Avisa a todos (Chat e Lista)
      Messages.broadcast({:ok, message})

      # 4. Reabertura automática se o cliente responder chamado fechado
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
      <!-- Aumentamos a largura para max-w-7xl e ajustamos a altura -->
            <div class="max-w-7xl mx-auto p-0 sm:p-4 flex flex-col h-[calc(100dvh-65px)] sm:h-[calc(100vh-100px)]">
        <!-- Cabeçalho do Chamado -->
        <div class="bg-base-100 border-b sm:border border-base-300 sm:rounded-t-xl p-3 sm:p-4 flex flex-col sm:flex-row justify-between sm:items-center gap-3 shadow-sm">
          <div>
            <h1 class="text-lg sm:text-xl font-bold flex flex-wrap items-center gap-2">
              {@ticket.subject}
              <span class={"badge badge-sm " <> if @ticket.status == :aberto, do: "badge-warning", else: (if @ticket.status == :em_andamento, do: "badge-primary", else: "badge-success")}>
                {@ticket.status}
              </span>
            </h1>
            <p class="text-xs sm:text-sm text-base-content/70 mt-1">
              Solicitante: <strong>{@ticket.solicitante.name}</strong>
              <%= if @ticket.atendente do %>
                | Atendente: <strong>{@ticket.atendente.name}</strong>
              <% end %>
            </p>
          </div>
          <div class="flex flex-wrap gap-2">
            <%= if @current_scope.user.role == :suporte do %>
              <button :if={@ticket.status == :aberto} phx-click="assign_ticket" class="btn btn-warning btn-sm flex-1 sm:flex-none">Assumir</button>
              <button :if={@ticket.status == :em_andamento} phx-click="resolve_ticket" class="btn btn-success btn-sm flex-1 sm:flex-none">Resolver</button>
            <% end %>
            <.link navigate={~p"/chamados"} class="btn btn-ghost btn-sm">Voltar</.link>
          </div>
        </div>

        <!-- Área das Mensagens (Ocupa todo o espaço restante) -->
        <!-- O 'min-h-0' é essencial para o scroll funcionar dentro de um flexbox -->
        <div class="flex-1 overflow-y-auto p-4 bg-base-200 border-x border-base-300 space-y-4 min-h-0" id="chat-container" phx-hook="ScrollToBottom">
          <%= for msg <- @messages do %>
            <div class={"chat " <> if msg.user_id == @current_scope.user.id, do: "chat-end", else: "chat-start"}>
              <div class="chat-header text-xs text-base-content/60 mb-1 flex items-center gap-2">
                {msg.user.name}
                <time class="text-[10px]">{Calendar.strftime(msg.inserted_at, "%d/%m %H:%M")}</time>
                <span :if={msg.internal} class="badge badge-warning badge-sm">Nota Interna</span>
              </div>
              <div class={"chat-bubble " <> if msg.internal, do: "chat-bubble-warning", else: (if msg.user_id == @current_scope.user.id, do: "chat-bubble-primary", else: "")}>
                <p :if={msg.body != ""}>{msg.body}</p>

                <div :if={msg.attachments != []} class="mt-2 space-y-2">
                  <%= for att <- msg.attachments do %>
                    <%= if String.starts_with?(att.content_type, "image/") do %>
                      <a href={att.path} target="_blank">
                        <img src={att.path} alt={att.filename} class="max-w-[250px] rounded-lg cursor-pointer hover:opacity-90 transition-opacity" />
                      </a>
                    <% else %>
                      <video src={att.path} controls class="max-w-[350px] rounded-lg mt-2 shadow-sm"></video>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Área do Formulário Integrada -->
                <!-- Área do Formulário Integrada -->
        <div class="bg-base-100 border-t sm:border border-base-300 sm:rounded-b-xl p-2 sm:p-3 shadow-sm">
          <.form for={@form} id="chat-form" phx-submit="send_message" phx-change="validate_upload" class="flex flex-col gap-2">

            <!-- Prévia dos arquivos -->
            <div :if={@uploads.image.entries != []} class="flex gap-2 mb-1 px-1">
              <%= for entry <- @uploads.image.entries do %>
                <div class="relative w-20 h-20 border rounded-lg bg-base-200 flex items-center justify-center overflow-hidden">
                  <%= if String.starts_with?(entry.client_type, "image/") do %>
                    <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                  <% else %>
                    <span class="text-[10px] text-center px-1 truncate">{entry.client_name}</span>
                  <% end %>
                  <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="absolute top-1 right-1 btn btn-circle btn-xs btn-error text-white">✕</button>
                </div>
              <% end %>
            </div>

            <!-- Barra de digitação estilo WhatsApp -->
            <div class="flex gap-2 items-end">
              <label class="btn btn-square btn-ghost text-base-content/70 hover:text-primary mb-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m18.375 12.739-7.693 7.693a4.5 4.5 0 0 1-6.364-6.364l10.94-10.94A3 3 0 1 1 19.5 7.372L8.552 18.32m.009-.01-.01.01m5.699-9.941-7.81 7.81a1.5 1.5 0 0 0 2.112 2.13" />
                </svg>
                <.live_file_input upload={@uploads.image} class="hidden" />
              </label>

              <.input
                field={@form[:body]}
                type="text"
                placeholder="Digite sua mensagem..."
                autocomplete="off"
                class="flex-1 input input-bordered w-full focus:outline-none focus:ring-1 focus:ring-primary mb-0.5"
              />

              <.button class="btn btn-primary btn-square mb-0.5">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5">
                  <path d="M3.478 2.404a.75.75 0 0 0-.926.941l2.432 7.905H13.5a.75.75 0 0 1 0 1.5H4.984l-2.432 7.905a.75.75 0 0 0 .926.94 60.519 60.519 0 0 0 18.445-8.986.75.75 0 0 0 0-1.218A60.517 60.517 0 0 0 3.478 2.404Z" />
                </svg>
              </.button>
            </div>

            <!-- Checkbox de Nota Interna -->
            <%= if @current_scope.user.role == :suporte do %>
              <label class="label cursor-pointer justify-start gap-2 w-fit px-1">
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
