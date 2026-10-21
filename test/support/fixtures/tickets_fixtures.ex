defmodule TicketElixir.TicketsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TicketElixir.Tickets` context.
  """

  @doc """
  Generate a ticket.
  """
  def ticket_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        status: "some status",
        subject: "some subject"
      })

    {:ok, ticket} = TicketElixir.Tickets.create_ticket(scope, attrs)
    ticket
  end
end
