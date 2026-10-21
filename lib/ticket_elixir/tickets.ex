defmodule TicketElixir.Tickets do
  import Ecto.Query, warn: false
  alias TicketElixir.Repo
  alias TicketElixir.Tickets.{Ticket, TicketRead}

  def subscribe_ticket(ticket_id) do
    Phoenix.PubSub.subscribe(TicketElixir.PubSub, "ticket_update:#{ticket_id}")
  end

  def subscribe_all_tickets do
    Phoenix.PubSub.subscribe(TicketElixir.PubSub, "tickets_global")
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

  def mark_as_read(ticket_id, user_id) do
    now = DateTime.utc_now(:second)

    Repo.insert_all(
      TicketRead,
      [%{ticket_id: ticket_id, user_id: user_id, last_read_at: now, inserted_at: now, updated_at: now}],
      on_conflict: [set: [last_read_at: now, updated_at: now]],
      conflict_target: [:user_id, :ticket_id]
    )
  end

  def list_tickets_with_unread(user) do
    base_query =
      if user.role == :suporte do
        from t in Ticket
      else
        from t in Ticket, where: t.solicitante_id == ^user.id
      end

    query =
      from t in base_query,
        left_join: r in TicketRead,
        on: r.ticket_id == t.id and r.user_id == ^user.id,
        left_join: m in assoc(t, :messages),
        on: m.inserted_at > coalesce(r.last_read_at, ^~U[1970-01-01 00:00:00Z]) and m.user_id != ^user.id,
        group_by: t.id,
        select: {t, count(m.id)},
        order_by: [desc: t.updated_at]

    Repo.all(query)
  end

  def get_ticket!(id), do: Repo.get!(Ticket, id)

  def get_ticket_with_messages!(id) do
    Repo.get!(Ticket, id)
    |> Repo.preload([:solicitante, :atendente, messages: [:user, :attachments]])
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

    def count_tickets(user, status) do
    query =
      if user.role == :suporte do
        from t in Ticket, where: t.status == ^status
      else
        from t in Ticket, where: t.solicitante_id == ^user.id and t.status == ^status
      end

    Repo.aggregate(query, :count, :id)
  end
end
