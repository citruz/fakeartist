defmodule FakeartistWeb.SessionController do
    use FakeartistWeb, :controller

    def create(conn, %{"user" => %{"username" => username}, "game-id" => game_id}) do
        conn
        |> put_session(:username, username)
        |> put_session(:user_id, UUID.uuid4())
        |> configure_session(renew: true)
        |> redirect(to: Routes.game_path(conn, :show, game_id))
    end

    def create(conn, %{"user" => %{"username" => username}}) do
        conn
        |> put_flash(:info, "Welcome back, " <> username <> "!")
        |> put_session(:username, username)
        |> put_session(:user_id, UUID.uuid4())
        |> configure_session(renew: true)
        |> redirect(to: "/")
    end
    
    def delete(conn, _) do
        conn
        |> configure_session(drop: true)
        |> redirect(to: "/")
    end
end