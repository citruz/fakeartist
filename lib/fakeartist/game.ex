defmodule Fakeartist.Game do
    use GenServer

    defstruct players: [], fsm: :none

    alias Fakeartist.{Game, Player, Rules}

    def start_link(name) when not is_nil name do
        GenServer.start_link(__MODULE__, name)
    end

    def init(name) do
        {:ok, player} = Player.start_link(name)
        {:ok, fsm} = Rules.start_link
        {:ok, %Game{players: [player], fsm: fsm}}
    end

    def get_players(pid) do
        GenServer.call(pid, :get_players)
    end

    def add_player(pid, name) when name != nil do
        GenServer.call(pid, {:add_player, name})
    end

    def start_game(pid) do
        GenServer.call(pid, :start_game)
    end

    def handle_call({:add_player, name}, _from, state) do
        Rules.add_player(state.fsm)
        |> add_player_reply(state, name)
    end

    def handle_call(:start_game, _from, state) do
        Rules.start_game(state.fsm)
        |> start_game_reply(state)
    end

    defp add_player_reply(:ok, state, name) do
        {:ok, player} = Player.start_link(name)
        state = Map.put(state, :players, state.players ++ [player])
        {:reply, :ok, state}
    end

    defp add_player_reply(reply, state, _name) do
        {:reply, reply, state}
    end

    defp start_game_reply(:ok, state) do
        {:reply, :ok, state}
    end

    defp start_game_reply(reply, state) do
        {:reply, reply, state}
    end

    def handle_call(:get_players, _from, state) do
        {:reply, state.players, state}
    end
end
