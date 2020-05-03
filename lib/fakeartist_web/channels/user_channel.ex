defmodule FakeartistWeb.UserChannel do
    use Phoenix.Channel

    alias Fakeartist.{Game, Global, Player}
  
    def join("user:" <> user_id, _params, socket) do    
        if socket.assigns.current_user.id == user_id do
            {:ok, socket}
        else
            {:error, "This is not your solo channel!"}
        end
    end
  end