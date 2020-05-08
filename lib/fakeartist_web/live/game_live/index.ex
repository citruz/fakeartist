defmodule FakeartistWeb.GameLive.Index do
  use FakeartistWeb, :live_view

  alias Fakeartist.{Global, Game}

  @impl true
  def mount(_params, %{"user_id" => user_id, "username" => username}, socket)
  when user_id != nil and username != nil do
    socket = socket
    |> assign(:user_id, user_id)
    |> assign(:username, username)
    |> assign(:games, fetch_games())
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do  
    socket
    |> assign(:page_title, "Listing Games")
  end

  @impl
  def handle_event("new_game", %{"user" => %{"num_rounds" => num_rounds}} = params, socket) do
    num_rounds = String.to_integer(num_rounds)
    {:ok, token, game} = Global.new_game(socket.assigns.username, socket.assigns.user_id, num_rounds)
    {:noreply,
        socket
        |> push_redirect(to: "/livegame/" <> token)} # TODO replace with proper Route.game_path
  end

  defp page_title(:show), do: "Show Games"
  defp page_title(:new), do: "New Game"

  defp fetch_games do
    Global.games()
  end
end