defmodule FakeartistWeb.GameChannel do
    use Phoenix.Channel

    alias Fakeartist.{Game, Global, Player}
  
    def join("game:" <> game_token, _params, socket) do
        IO.puts("join game: " <> game_token <> " user: " <> socket.assigns.current_user.name)

        game = Global.get_game(game_token)
        player_names = Enum.map(Game.get_players(game), fn player -> Player.name(player) end)

        send(self, {:after_join, game})

        {:ok, %{players: player_names}, socket}
    end

    def handle_in("draw", body, socket) do
        IO.puts("new message: #{inspect(body)}")
        IO.puts("socket: #{inspect(socket)}")
        broadcast!(socket, "draw", body)
        {:noreply, socket}
    end

    def handle_info({:after_join, game}, socket) do
        player_name = socket.assigns.current_user.name
        Game.add_player(game, player_name)
        broadcast! socket, "player:joined", %{player: player_name}
        {:noreply, socket}
      end
  end