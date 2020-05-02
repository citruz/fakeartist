defmodule FakeartistWeb.RoomChannel do
    use Phoenix.Channel
  
    def join("room:lobby", _message, socket) do
        {:ok, socket}
    end

    def join("room:" <> _private_room_id, _params, _socket) do
        {:error, %{reason: "unauthorized"}}
    end

    def handle_in("draw", body, socket) do
        IO.puts("new message: #{inspect(body)}")
        broadcast!(socket, "draw", body)
        {:noreply, socket}
    end
  end