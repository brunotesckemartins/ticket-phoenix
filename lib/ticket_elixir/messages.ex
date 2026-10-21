defmodule TicketElixir.Messages do
  import Ecto.Query, warn: false
  alias TicketElixir.Repo
  alias TicketElixir.Messages.{Message, Attachment}

  def subscribe(ticket_id) do
    Phoenix.PubSub.subscribe(TicketElixir.PubSub, "ticket:#{ticket_id}")
  end

  def broadcast({:ok, message} = result) do
    # Carrega o usuário e os anexos para enviar pro front
    message = Repo.preload(message, [:user, :attachments])

    Phoenix.PubSub.broadcast(
      TicketElixir.PubSub,
      "ticket:#{message.ticket_id}",
      {:new_message, message}
    )
    result
  end
  def broadcast(result), do: result

  def list_messages(ticket_id) do
    from(m in Message,
      where: m.ticket_id == ^ticket_id,
      order_by: [asc: m.inserted_at],
      preload: [:user, :attachments] # <--- AQUI
    )
    |> Repo.all()
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def create_attachment(attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert!()
  end
end
