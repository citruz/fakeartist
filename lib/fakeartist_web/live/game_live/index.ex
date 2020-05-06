defmodule FakeartistWeb.GameLive.Index do
    use FakeartistWeb, :live_view

    alias Fakeartist.{Global, Game}

    # @impl true
    # def mount(params, %{"user_id" => user_id, "username" => username}, socket)
    # when user_id != nil and username != nil do
    #   IO.puts("params: #{inspect params}")
    #   IO.puts("socket: #{inspect socket}")
    #       socket = socket
    #       |> assign(:user_id, user_id)
    #       |> assign(:username, username)
    #       #|> assign(:games, fetch_games())
          
    #     #   {:ok, token, game} = Global.new_game(socket.assigns.username, socket.assigns.user_id, 22)
    #     #   IO.puts("save0: #{inspect token}")
    #     #   IO.puts("save1: #{inspect Game.props(game)}")
    #     #   IO.puts("save2: #{inspect Global.games[token]}")
    #     #   IO.puts("save3: #{inspect Game.props(Global.games[token])}")
    #     #  socket = socket
    #     #  |> put_flash(:info, "User updated successfully")
    #       {:ok, socket}
    # end

    @impl true
    def mount(_params, _session, socket) do
      socket = socket
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

    @impl true
    def handle_event("addgame", params, socket) do
      IO.puts("addgame: #{inspect params}")
      {:ok, token, game} = Global.new_game("some_username", "some_user_id", 2)
      IO.puts("addgame: #{inspect Game.props(game)}")
      IO.puts("addgame: #{inspect Global.games[token]}")
      IO.puts("addgame: #{inspect Game.props(Global.games[token])}")

      socket = socket 
      |> assign(:games, fetch_games())
      |> push_redirect(to: "/livegame")
      {:noreply, socket}
    end

    # def handle_event("save", %{"user" => %{"num_rounds" => num_rounds}} = params, socket) do
    #   IO.puts("save: #{inspect params}")
    #   num_rounds = String.to_integer(num_rounds)
    #   {:ok, token, game} = Global.new_game(socket.assigns.username, socket.assigns.user_id, num_rounds)
    #   IO.puts("save1: #{inspect Game.props(game)}")
    #   IO.puts("save2: #{inspect Global.games[token]}")
    #   IO.puts("save3: #{inspect Game.props(Global.games[token])}")
    #   {:noreply,
    #      socket
    #      |> put_flash(:info, "User updated successfully")
    #      |> push_redirect(to: "/livegame")}
    #      #|> push_redirect(to: Routes.game_index_path(@socket, :show, token))}
    # end
  
    defp page_title(:show), do: "Show Games"
    defp page_title(:new), do: "New Game"

    defp fetch_games do
      Global.games()
    end
end