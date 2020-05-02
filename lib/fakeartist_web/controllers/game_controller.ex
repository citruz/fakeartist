defmodule FakeartistWeb.GameController do
    use FakeartistWeb, :controller

    alias Fakeartist.Global

    def index(conn, _params) do
        games = Global.games
        render(conn, "index.html", games: games)
    end

    def show(conn, %{"id" => token}) do
        case Global.get_game(token) do
            nil ->
                conn
                |> put_flash(:error, "Game does not exist")
                |> redirect(to: "/")
            _ ->
                render(conn, "show.html", token: token)
        end
    end

    def create(conn, %{}) do
        token = UUID.uuid4()
        username = get_session(conn, :username)
        IO.puts(username)
        game = Global.new_game(token, username)
        conn
        |> put_flash(:info, "New game started!")
        |> redirect(to: Routes.game_path(conn, :show, token))
    end
end