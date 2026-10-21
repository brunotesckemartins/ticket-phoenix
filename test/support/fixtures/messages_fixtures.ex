defmodule TicketElixir.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TicketElixir.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        body: "some body",
        internal: true
      })
      |> TicketElixir.Messages.create_message()

    message
  end
end
