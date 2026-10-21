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

  @doc """
  Generate a attachment.
  """
  def attachment_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        content_type: "some content_type",
        filename: "some filename",
        path: "some path"
      })

    {:ok, attachment} = TicketElixir.Messages.create_attachment(scope, attrs)
    attachment
  end
end
