defmodule FakeartistWeb.GameChannel do
    use Phoenix.Channel

    alias Fakeartist.{Game, Global, Player}
  
    def join("game:" <> game_token, _params, socket) do
        IO.puts("join game: " <> game_token <> " user: " <> socket.assigns.current_user.name)

        game = Global.get_game(game_token)

        player_name = socket.assigns.current_user.name
        case Game.add_player(game, player_name, socket.assigns.current_user.id) do
            :ok ->
                IO.puts("OK")
                send(self(), {:after_join, player_name})
                send(self(), {:send_state, game})
                socket = assign(socket, :game, game)
                {:ok, socket}
            reply ->
                IO.puts("error: #{inspect reply}")
                {:error, %{error: Atom.to_string(reply)}}
        end
    end

    def join("user:" <> user_id, _params, socket) do    
        if socket.assigns.current_user.id == user_id do
            {:ok, socket}
        else
            {:error, "This is not your solo channel!"}
        end
    end

    def handle_in("start_game", body, socket) do
        Game.start_game(socket.assigns.game)
        send(self(), {:send_state, socket.assigns.game})
        {:noreply, socket}
    end

    def handle_in("draw", body, socket) do
        game = socket.assigns.game
        player_id = socket.assigns.current_user.id
        case Game.can_draw?(game, player_id) do
            false -> {:noreply, socket}
            color ->
                body = Map.put(body, :color, color)
                broadcast!(socket, "draw", body)
                {:noreply, socket}
        end
    end

    def handle_in("select_category", %{"category" => category, "subject" => subject}, socket) do
        IO.puts("got category: " <> category <> " subject: " <> subject <> " by user: " <> socket.assigns.current_user.name)

        Game.select_category(socket.assigns.game, category, subject, socket.assigns.current_user.id)

        send(self(), {:send_state, socket.assigns.game})
        send(self(), {:send_subject, socket.assigns.game})
        {:noreply, socket}
    end

    def handle_info({:after_join, player_name}, socket) do
        broadcast! socket, "player:joined", %{player: player_name}
        {:noreply, socket}
    end

    def handle_info({:send_state, game}, socket) do
        IO.puts("send state")

        case Game.get_state(game) do
            :selecting_category ->
                player = Game.get_question_master(game)
                FakeartistWeb.Endpoint.broadcast("user:" <> Player.id(player), "select_category", %{})
            :drawing -> send_subject_internal(game)
            _ -> :ignore
        end

        broadcast! socket, "game:state", Game.props(game)
        {:noreply, socket}
    end

    defp send_subject_internal(game) do
        Enum.each(Game.get_players(game), fn player -> 
            subject = Game.get_subject(game)
            if Player.is_fake?(player) do
                FakeartistWeb.Endpoint.broadcast("user:" <> Player.id(player), "subject", %{subject: "X"})
            else
                FakeartistWeb.Endpoint.broadcast("user:" <> Player.id(player), "subject", %{subject: subject})
            end
        end)
    end

    def handle_info({:send_subject, game}, socket) do
        send_subject_internal(game)
        {:noreply, socket}
    end
  end