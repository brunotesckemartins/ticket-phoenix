defmodule TicketElixir.MessagesTest do
  use TicketElixir.DataCase

  alias TicketElixir.Messages

  describe "messages" do
    alias TicketElixir.Messages.Message

    import TicketElixir.MessagesFixtures

    @invalid_attrs %{internal: nil, body: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Messages.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{internal: true, body: "some body"}

      assert {:ok, %Message{} = message} = Messages.create_message(valid_attrs)
      assert message.internal == true
      assert message.body == "some body"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      update_attrs = %{internal: false, body: "some updated body"}

      assert {:ok, %Message{} = message} = Messages.update_message(message, update_attrs)
      assert message.internal == false
      assert message.body == "some updated body"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end
  end

  describe "attachments" do
    alias TicketElixir.Messages.Attachment

    import TicketElixir.AccountsFixtures, only: [user_scope_fixture: 0]
    import TicketElixir.MessagesFixtures

    @invalid_attrs %{filename: nil, path: nil, content_type: nil}

    test "list_attachments/1 returns all scoped attachments" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      other_attachment = attachment_fixture(other_scope)
      assert Messages.list_attachments(scope) == [attachment]
      assert Messages.list_attachments(other_scope) == [other_attachment]
    end

    test "get_attachment!/2 returns the attachment with given id" do
      scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      other_scope = user_scope_fixture()
      assert Messages.get_attachment!(scope, attachment.id) == attachment
      assert_raise Ecto.NoResultsError, fn -> Messages.get_attachment!(other_scope, attachment.id) end
    end

    test "create_attachment/2 with valid data creates a attachment" do
      valid_attrs = %{filename: "some filename", path: "some path", content_type: "some content_type"}
      scope = user_scope_fixture()

      assert {:ok, %Attachment{} = attachment} = Messages.create_attachment(scope, valid_attrs)
      assert attachment.filename == "some filename"
      assert attachment.path == "some path"
      assert attachment.content_type == "some content_type"
      assert attachment.user_id == scope.user.id
    end

    test "create_attachment/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.create_attachment(scope, @invalid_attrs)
    end

    test "update_attachment/3 with valid data updates the attachment" do
      scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      update_attrs = %{filename: "some updated filename", path: "some updated path", content_type: "some updated content_type"}

      assert {:ok, %Attachment{} = attachment} = Messages.update_attachment(scope, attachment, update_attrs)
      assert attachment.filename == "some updated filename"
      assert attachment.path == "some updated path"
      assert attachment.content_type == "some updated content_type"
    end

    test "update_attachment/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      attachment = attachment_fixture(scope)

      assert_raise MatchError, fn ->
        Messages.update_attachment(other_scope, attachment, %{})
      end
    end

    test "update_attachment/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Messages.update_attachment(scope, attachment, @invalid_attrs)
      assert attachment == Messages.get_attachment!(scope, attachment.id)
    end

    test "delete_attachment/2 deletes the attachment" do
      scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      assert {:ok, %Attachment{}} = Messages.delete_attachment(scope, attachment)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_attachment!(scope, attachment.id) end
    end

    test "delete_attachment/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      assert_raise MatchError, fn -> Messages.delete_attachment(other_scope, attachment) end
    end

    test "change_attachment/2 returns a attachment changeset" do
      scope = user_scope_fixture()
      attachment = attachment_fixture(scope)
      assert %Ecto.Changeset{} = Messages.change_attachment(scope, attachment)
    end
  end
end
