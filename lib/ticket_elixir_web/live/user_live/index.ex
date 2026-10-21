defmodule TicketElixirWeb.UserLive.Index do
  use TicketElixirWeb, :live_view
  alias TicketElixir.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if user.role != :suporte do
      {:ok, push_navigate(socket, to: ~p"/chamados")}
    else
      users = Accounts.list_users()
      # Adicionamos o reset_info para guardar a mensagem na tela
      {:ok, assign(socket, users: users, reset_info: nil)}
    end
  end

  @impl true
  def handle_event("change_role", %{"id" => id, "role" => role}, socket) do
    user = Enum.find(socket.assigns.users, &(&1.id == id))
    role_atom = String.to_existing_atom(role)

    {:ok, updated_user} = Accounts.update_user_role(user, role_atom)

    users = Enum.map(socket.assigns.users, fn u ->
      if u.id == updated_user.id, do: updated_user, else: u
    end)

    {:noreply, assign(socket, users: users)}
  end

  @impl true
  def handle_event("reset_password", %{"id" => id}, socket) do
    user = Enum.find(socket.assigns.users, &(&1.id == id))
    temp_password = "Gmus@1234"

    {:ok, _} = Accounts.reset_user_password(user, temp_password)

    # Salva a mensagem no assign em vez de usar flash
    {:noreply, assign(socket, :reset_info, "A senha de #{user.name} foi redefinida para: #{temp_password}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto p-4">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-bold">Gestão de Usuários</h1>
          <.link navigate={~p"/chamados"} class="btn btn-sm">Voltar aos Chamados</.link>
        </div>

        <!-- MENSAGEM FIXA DA SENHA -->
        <div :if={@reset_info} class="alert alert-success mb-6 shadow-lg">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          <span class="font-bold">{@reset_info}</span>
          <div>
            <button phx-click={JS.push("clear_info")} class="btn btn-sm btn-ghost">Fechar</button>
          </div>
        </div>

        <div class="overflow-x-auto bg-base-100 rounded-lg shadow border border-base-300">
          <table class="table w-full">
            <thead>
              <tr>
                <th>Nome</th>
                <th>E-mail</th>
                <th>Perfil</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody>
              <%= for user <- @users do %>
                <tr>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td>
                    <select
                      phx-change="change_role"
                      phx-value-id={user.id}
                      name="role"
                      class="select select-bordered select-sm"
                    >
                      <option value="solicitante" selected={user.role == :solicitante}>Solicitante</option>
                      <option value="suporte" selected={user.role == :suporte}>Suporte</option>
                      <option value="admin" selected={user.role == :admin}>Admin</option>
                    </select>
                  </td>
                  <td>
                    <button
                      phx-click="reset_password"
                      phx-value-id={user.id}
                      class="btn btn-warning btn-sm"
                    >
                      Redefinir Senha
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Evento para fechar a mensagem verde
  @impl true
  def handle_event("clear_info", _params, socket) do
    {:noreply, assign(socket, :reset_info, nil)}
  end
end
