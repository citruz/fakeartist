defmodule Fakeartist.Global do
    use Agent

    alias Fakeartist.Game

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def games do
        Agent.get(__MODULE__, &(&1))
    end

    def new_game(token, player_name, player_id) do
        {:ok, game} = Game.start_link(player_name, player_id)
        Agent.update(__MODULE__, &Map.put_new(&1, token, game))
        game
    end

    def get_game(token) do
        Agent.get(__MODULE__, &Map.get(&1, token))
    end
end
