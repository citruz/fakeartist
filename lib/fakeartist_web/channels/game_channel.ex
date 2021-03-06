defmodule FakeartistWeb.GameChannel do
  use Phoenix.Channel

  alias Fakeartist.{Game, Global}

  def join("draw:" <> game_token, _params, socket) do
    IO.puts("join game: " <> game_token <> " user: " <> socket.assigns.current_user.name)

    game = Global.get_game(game_token)

    if game == nil do
      {:error, :game_not_started}
    else
      player_id = socket.assigns.current_user.id
      player_name = socket.assigns.current_user.name

      case Game.add_player(game, player_name, player_id) do
        {:ok, _player} ->
          IO.puts("OK")
          socket = assign(socket, :game, game)
          {:ok, %{}, socket}

        reply ->
          IO.puts("error: #{inspect(reply)}")
          {:error, %{error: Atom.to_string(reply)}}
      end
    end
  end

  def handle_in("draw", body, socket) do
    game = socket.assigns.game
    player_id = socket.assigns.current_user.id

    case Game.can_draw?(game, player_id) do
      false ->
        {:noreply, socket}

      color ->
        {erase, body} = Map.pop(body, "erase", false)
        # "erase" is just drawing white
        new_color = if erase, do: "white", else: color
        body = Map.put(body, :color, new_color)
        broadcast!(socket, "draw", body)
        {:noreply, socket}
    end
  end
end
