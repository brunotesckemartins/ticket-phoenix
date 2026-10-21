defmodule TicketElixirWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TicketElixirWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
            <header class="navbar px-2 sm:px-6 lg:px-8 border-b border-base-300 bg-base-100 sticky top-0 z-50">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2 hover:opacity-80 transition-opacity">
          <.icon name="hero-ticket" class="w-6 h-6 sm:w-7 sm:h-7 text-primary" />
          <!-- Esconde o texto "HelpDesk" em telas muito pequenas -->
          <span class="text-lg sm:text-xl font-bold tracking-tight hidden sm:inline-block">HelpDesk</span>
        </a>
      </div>

      <div class="flex-none">
        <ul class="flex px-1 space-x-1 sm:space-x-2 items-center">

          <!-- Botão de Usuários (escondido no celular, visível no desktop) -->
          <li :if={@current_scope && @current_scope.user.role == :suporte} class="hidden md:block">
            <.link navigate={~p"/usuarios"} class="btn btn-ghost btn-sm font-medium text-base-content/80">
              Usuários
            </.link>
          </li>

          <!-- Toggle de Tema -->
          <li>
            <.theme_toggle />
          </li>

          <!-- Menu do Usuário -->
          <li :if={@current_scope && @current_scope.user}>
            <div class="dropdown dropdown-end ml-1 sm:ml-2">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar placeholder">
                <div class="bg-neutral text-neutral-content rounded-full w-8 h-8 sm:w-9 sm:h-9">
                  <span>{String.first(@current_scope.user.name)}</span>
                </div>
              </div>
              <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-100 rounded-box w-56 mt-4 border border-base-200">
                <div class="px-4 py-2 border-b border-base-200 mb-1">
                  <p class="text-sm font-semibold truncate">{@current_scope.user.name}</p>
                  <p class="text-xs text-base-content/60 truncate">{@current_scope.user.email}</p>
                </div>
                <!-- Adiciona o link de usuários no menu dropdown do celular -->
                <li :if={@current_scope.user.role == :suporte} class="md:hidden">
                  <.link navigate={~p"/usuarios"} class="text-sm">Gestão de Usuários</.link>
                </li>
                <li><.link navigate={~p"/users/settings"} class="text-sm">Configurações</.link></li>
                <li><.link href={~p"/users/log-out"} method="delete" class="text-sm text-error">Sair da conta</.link></li>
              </ul>
            </div>
          </li>

        </ul>
      </div>
    </header>

    <main class="px-4 py-8 sm:px-6 lg:px-8 flex-1">
      <div class="mx-auto max-w-7xl">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
