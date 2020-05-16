defmodule Fakeartist.Global do
  use GenServer

  defstruct games: %{}

  alias Fakeartist.{Game, Global}

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: :global)
  end

  def init(_) do
    {:ok, %Global{}}
  end

  def games do
    GenServer.call(:global, :games)
  end

  def new_game(player_name, player_id) do
    GenServer.call(:global, {:new_game, player_name, player_id})
  end

  def get_game(token) do
    GenServer.call(:global, {:get_game, token})
  end

  def handle_call(:games, _from, state) do
    {:reply, state.games, state}
  end

  def handle_call({:new_game, player_name, player_id}, _from, state) do
    token = UUID.uuid4()
    {:ok, game} = Game.start_link(player_name, player_id)
    games = Map.put(state.games, token, game)
    state = Map.put(state, :games, games)
    {:reply, {:ok, token, game}, state}
  end

  def handle_call({:get_game, token}, _from, state) do
    {:reply, Map.get(state.games, token), state}
  end
end
