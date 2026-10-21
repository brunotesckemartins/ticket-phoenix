defmodule TicketElixir.Messages do
  import Ecto.Query, warn: false
  alias TicketElixir.Repo
  alias TicketElixir.Messages.{Message, Attachment}

  def subscribe(ticket_id) do
    Phoenix.PubSub.subscribe(TicketElixir.PubSub, "ticket:#{ticket_id}")
  end

  def broadcast({:ok, message} = result) do
    message = Repo.preload(message, [:user, :attachments])

    # 1. Avisa o Chat (tela aberta)
    Phoenix.PubSub.broadcast(
      TicketElixir.PubSub,
      "ticket:#{message.ticket_id}",
      {:new_message, message}
    )

    # 2. Avisa a Lista de Chamados (badge)
    Phoenix.PubSub.broadcast(
      TicketElixir.PubSub,
      "tickets_global",
      {:new_ticket_message, message.ticket_id}
    )
    result
  end
  def broadcast(result), do: result

  def list_messages(ticket_id) do
    from(m in Message,
      where: m.ticket_id == ^ticket_id,
      order_by: [asc: m.inserted_at],
      preload: [:user, :attachments]
    )
    |> Repo.all()
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        # Atualiza o horário do ticket usando :second para remover os microssegundos
        TicketElixir.Tickets.get_ticket!(message.ticket_id)
        |> Ecto.Changeset.change(updated_at: DateTime.utc_now(:second)) # <-- MUDANÇA AQUI
        |> Repo.update!()

        {:ok, message}
      error -> error
    end
  end

  def create_attachment(attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert!()
  end
end
