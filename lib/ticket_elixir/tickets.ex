defmodule TicketElixir.Tickets do
  import Ecto.Query, warn: false
  alias TicketElixir.Repo
  alias TicketElixir.Tickets.Ticket

  def subscribe_ticket(ticket_id) do
    Phoenix.PubSub.subscribe(TicketElixir.PubSub, "ticket_update:#{ticket_id}")
  end

  def broadcast_ticket({:ok, ticket} = result) do
    Phoenix.PubSub.broadcast(
      TicketElixir.PubSub,
      "ticket_update:#{ticket.id}",
      {:ticket_updated, ticket}
    )
    result
  end
  def broadcast_ticket(result), do: result

  def list_all_tickets do
    from(t in Ticket, order_by: [desc: t.updated_at]) |> Repo.all()
  end

  def list_tickets_for_user(user_id) do
    from(t in Ticket, where: t.solicitante_id == ^user_id, order_by: [desc: t.updated_at]) |> Repo.all()
  end

  def get_ticket!(id), do: Repo.get!(Ticket, id)

  def get_ticket_with_messages!(id) do
    Repo.get!(Ticket, id)
    |> Repo.preload([:solicitante, :atendente, messages: [:user, :attachments]]) # <--- AQUI
  end

  def create_ticket(attrs \\ %{}) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
    |> broadcast_ticket()
  end

  def change_ticket(%Ticket{} = ticket, attrs \\ %{}) do
    Ticket.changeset(ticket, attrs)
  end
end
