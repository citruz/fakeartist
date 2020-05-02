defmodule FakeartistWeb.GameChannel do
    use Phoenix.Channel
  
    def join("game:" <> game_token, _params, socket) do
        IO.puts("join game: " <> game_token <> " user: " <> socket.assigns.current_user.name)
        {:ok, socket}
    end

    def handle_in("draw", body, socket) do
        IO.puts("new message: #{inspect(body)}")
        IO.puts("socket: #{inspect(socket)}")
        broadcast!(socket, "draw", body)
        {:noreply, socket}
    end
  end