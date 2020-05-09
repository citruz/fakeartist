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

  # not logged in
  def mount(_params, _session, socket)do
    socket = socket
    |> assign(:username, "")
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

  defp fetch_games do
    
    Enum.map(Global.games(), fn {token, g} -> %{
      token: token,
      num_players: length(Game.get_players(g)),
      state: Game.get_state(g)
    }
    end)
  end
end