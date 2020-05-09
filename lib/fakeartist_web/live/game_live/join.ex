defmodule FakeartistWeb.GameLive.Join do
  use FakeartistWeb, :live_view
    
  @impl true
  def mount(%{"id" => token}, %{"user_id" => user_id, "username" => username}, socket)
  when user_id != nil and username != nil do
    # is already logged in, redirect to play
    socket = socket
    |> push_redirect(to: Routes.game_play_path(socket, :play, token))
    {:ok, socket}
  end
  
  # not logged in
  def mount(%{"id" => token}, _session, socket) do
    socket = socket
    |> assign(:game_token, token)
    {:ok, socket}
  end
  
end