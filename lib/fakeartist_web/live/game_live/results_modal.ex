defmodule FakeartistWeb.GameLive.ResultsModal do
  use FakeartistWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {result, player_infos} = assigns.results

    socket =
      socket
      |> assign(:result, result)
      |> assign(:player_infos, player_infos)
      |> assign(:num_players, length(player_infos))
      |> assign(
        :fake_artist,
        Enum.find_value(player_infos, fn {name, _, fake?, _} -> if fake?, do: name end)
      )
      |> assign(assigns)

    {:ok, socket}
  end
end
