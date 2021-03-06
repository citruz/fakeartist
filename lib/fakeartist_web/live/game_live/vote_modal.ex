defmodule FakeartistWeb.GameLive.VoteModal do
  use FakeartistWeb, :live_component

  @impl true
  def update(assigns, socket) do
    myself = Enum.find(assigns.players, fn p -> p.id == assigns.my_id end)

    socket =
      socket
      |> assign(assigns)
      |> assign(:myself, myself)

    {:ok, socket}
  end
end
