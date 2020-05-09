defmodule FakeartistWeb.SessionController do
    use FakeartistWeb, :controller

    alias Fakeartist.Global

    defp check_username(conn, username) do
        if String.length(String.trim(username)) == 0 do
            conn
            |> put_flash(:error, "Invalid username")
            |> redirect(to: "/")
            |> halt
        else
            conn
        end
    end

    defp return_error(conn) do
        conn
        |> put_flash(:error, "Invalid parameter")
        |> redirect(to: "/")
        |> halt
    end

    defp check_game_parameters(conn, num_rounds) do
        case Integer.parse(num_rounds) do
        {num, ""} when num > 0 ->
            conn
        _ ->
            conn |> return_error
        end
    end

    defp create_game(conn, num_rounds) do
        username = get_session(conn, :username)
        user_id = get_session(conn, :user_id)
        case Global.new_game(username, user_id, num_rounds) do
        {:ok, token, _game} ->
            conn
            |> redirect(to: Routes.game_play_path(conn, :play, token))
        _ ->
            conn
            |> put_flash(:error, "failed to create game")
            |> redirect(to: "/")
        end
    end

    defp generate_user_id(conn) do
        case get_session(conn, :user_id) do
        nil ->
            # generate unique user id
            conn |> put_session(:user_id, UUID.uuid4())
        _ ->
            # already has id, no need to regenerate
            conn
        end
    end

    # join game
    def create(conn, %{"user" => %{"username" => username}, "game_id" => game_id}) do
        IO.inspect(get_session(conn))
        conn
        |> check_username(username)
        |> put_session(:username, username)
        |> generate_user_id
        |> configure_session(renew: true)
        |> redirect(to: Routes.game_play_path(conn, :play, game_id))
    end

    # create game
    def create(conn, %{"user" => %{"username" => username, "num_rounds" => num_rounds}}) do
        IO.inspect(get_session(conn))
        conn
        |> check_username(username)
        |> check_game_parameters(num_rounds)
        |> put_session(:username, username)
        |> generate_user_id
        |> configure_session(renew: true)
        # TODO this is not nice, think of a way to pass num from check_game_parameters down here
        |> create_game(String.to_integer(num_rounds))
    end
    
    def delete(conn, _) do
        conn
        |> configure_session(drop: true)
        |> redirect(to: "/")
    end
end