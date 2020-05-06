defmodule Fakeartist.Global do
    use Agent

    alias Fakeartist.Game

    def start_link(_) do
        Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def games do
        Agent.get(__MODULE__, &(&1))
    end

    def new_game(player_name, player_id, num_rounds) do
        IO.puts("new_game: #{inspect player_name} #{inspect player_id} #{inspect num_rounds}")
        token = UUID.uuid4()
        IO.puts("new_game: token #{inspect token}")
        {:ok, game} = Game.start_link(player_name, player_id, num_rounds)
        IO.puts("new_game: #{inspect game}")
        Agent.update(__MODULE__, &Map.put_new(&1, token, game))
        {:ok, token, game}
    end

    def get_game(token) do
        Agent.get(__MODULE__, &Map.get(&1, token))
    end
end
