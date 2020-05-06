defmodule FakeartistWeb.GameLive.Show do
    use FakeartistWeb, :live_view
  
    alias Fakeartist.{Game, Global}

    @impl true
    def mount(_params, _session, socket) do
      {:ok, socket}
    end
  
    @impl true
    def handle_params(%{"id" => token}, _, socket) do
      socket = case Global.get_game(token) do
        nil ->
          socket
            |> put_flash(:error, "Game does not exist")
            |> redirect(to: "/")
        game ->
          socket
          |> assign(:game, game)
      end
      {:noreply, socket}
    end
  
    defp page_title(:show), do: "Show User"
  end
  