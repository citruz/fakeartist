defmodule FakeartistWeb.UserChannel do
    use Phoenix.Channel
  
    def join("user:" <> user_id, _params, socket) do    
        if socket.assigns.current_user.id == user_id do
            {:ok, socket}
        else
            {:error, "unauthorized"}
        end
    end
  end