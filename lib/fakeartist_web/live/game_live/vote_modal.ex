defmodule FakeartistWeb.GameLive.VoteModal do
  use FakeartistWeb, :live_component

  alias Fakeartist.{Game, Player}

  @impl true
  def update(assigns, socket) do
    IO.puts("UPDATE #{inspect(assigns)}")

    myself = Enum.find(assigns.players, fn p -> p.id == assigns.my_id end)

    socket =
      socket
      |> assign(assigns)
      |> assign(:myself, myself)

    {:ok, socket}
  end
end
