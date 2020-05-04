defmodule FakeartistWeb.GameController do
    use FakeartistWeb, :controller

    alias Fakeartist.Global

    plug :check_login when action in [:create]
    plug :check_join when action in [:show]

    defp check_join(%Plug.Conn{assigns: %{current_user: nil}, path_params: %{"id" => id}} = conn, opts) do
        conn
        |> put_flash(:info, "Please choose a name")
        |> redirect(to: "/?join=" <> id)
        |> halt
    end
    defp check_join(%Plug.Conn{assigns: %{current_user: nil}} = conn, opts) do
        conn
        |> redirect(to: "/")
        |> halt
    end
    defp check_join(conn, _opts), do: conn

    defp check_login(%Plug.Conn{assigns: %{current_user: nil}} = conn, opts) do
        conn
        |> put_flash(:error, "Unauthorized")
        |> redirect(to: "/")
        |> halt
    end
    defp check_login(conn, _opts), do: conn

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

    def create(conn, %{"user" => %{"num_rounds" => num_rounds}}) do
        num_rounds = String.to_integer(num_rounds)
        token = UUID.uuid4()
        username = get_session(conn, :username)
        IO.puts(username)
        game = Global.new_game(token, username, get_session(conn, :user_id), num_rounds)
        conn
        |> redirect(to: Routes.game_path(conn, :show, token))
    end
end