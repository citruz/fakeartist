defmodule FakeartistWeb.GameLive.Index do
  use FakeartistWeb, :live_view

  alias Fakeartist.{Global, Game}

  @impl true
  def mount(_params, %{"user_id" => user_id, "username" => username}, socket)
      when user_id != nil and username != nil do
    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:username, username)
      |> assign(:games, fetch_games())

    {:ok, socket}
  end

  # not logged in
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:username, "")
      |> assign(:games, fetch_games())

    {:ok, socket}
  end

  defp fetch_games do
    Enum.map(Global.games(), fn {token, g} ->
      %{
        token: token,
        num_players: length(Game.get_players(g)),
        state: Game.get_state(g)
      }
    end)
  end
end
