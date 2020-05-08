defmodule FakeartistWeb.GameLive.Show do
    use FakeartistWeb, :live_view
  
    alias Fakeartist.{Game, Global, Player}
    alias FakeartistWeb.Endpoint

    @impl true
    def mount(%{"id" => game_token}, %{"user_id" => user_id, "username" => username}, socket) 
    when user_id != nil and username !=nil do
        game = Global.get_game(game_token)
        if game == nil do
            socket = socket
            |> put_flash(:error, "Game does not exist")
            |> redirect(to: "/livegame") # TODO replace with /
            {:ok, socket}
        else
            # join game
            case Game.add_player(game, username, user_id) do
                {:ok, player} ->
                    topic = "game:" <> game_token
                    Endpoint.subscribe(topic)
                    Endpoint.broadcast_from(self(), topic, "new_player", %{})
                    socket = socket
                    |> assign(:topic, topic)
                    |> assign(:token, game_token)
                    |> assign(:game, game)
                    |> assign(:player, player)
                    |> assign(:player_id, user_id)
                    |> assign(:page_title, "Game")
                    |> update_game_state
                    {:ok, socket}
                _ ->
                    socket = socket
                    |> put_flash(:error, "Error joining game")
                    |> redirect(to: "/livegame") # TODO replace with /
                    {:ok, socket}
            end    
        end
    end

    # unauthenticated
    def mount(%{"id" => game_token}, _, socket) do
        socket = socket
        |> put_flash(:info, "Please choose a username first")
        |> redirect(to: "/?join=" <> game_token)
        {:ok, socket}
    end

    defp update_game_state(socket) do
        game = socket.assigns.game
        socket
        |> assign(:players, Game.get_players(game))
        |> assign(:state, Game.get_state(game))
    end
    #
    # PubSub
    #

    def handle_info(%{event: "new_player"}, socket) do
        IO.puts("NEW PLAYER")
        socket = socket
        |> update_game_state
        {:noreply, socket}
    end

    def handle_info(%{event: "new_state"}, socket) do
        IO.puts("NEW STATE")
        socket = socket
        |> update_game_state
        {:noreply, socket}
    end

    def handle_info(event, socket) do
        IO.puts("handle_info: #{inspect event}")
        {:noreply, socket}
    end


    #
    # actions
    #
    def handle_event("start_game", _params, socket) do
        if Game.start_game(socket.assigns.game, socket.assigns.player_id) == :ok do
            Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
            send(self(), %{event: "new_state"})
        end
        {:noreply, socket}
    end
  
    #
    # render helpers
    #
    defp render_state_div(assigns, :initialized) do
        "Waiting for other players..."
    end
    defp render_state_div(assigns, state) when state in [:ready, :waiting_for_next_game] do
        if Player.is_question_master?(assigns.player) do
            ~L"""
                <button phx-click="start_game">Start Game</button>
            """
        else
            "Waiting for Question Master to start the game"
        end
    end
    defp render_state_div(assigns, other_state) do
        other_state
    end
end
  