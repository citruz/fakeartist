defmodule Fakeartist.Rules do
    @behaviour :gen_statem

    def start_link do
        :gen_statem.start_link(__MODULE__, :initialized, [])
    end

    def init(_) do
        {:ok, :initialized, []}
    end

    def callback_mode(), do: :state_functions

    def code_change(_vsn, state_name, state_data, _extra) do 
        {:ok, state_name, state_data}
    end

    def terminate(_reason, _state, _data), do: :nothing

    ## transitions

    def show_current_state(fsm) do
        :gen_statem.call(fsm, :show_current_state)
    end

    def add_player(fsm) do
        :gen_statem.call(fsm, :add_player)
    end

    def start_game(fsm) do
        :gen_statm.call(fsm, :start_game)
    end

    def select_category(fsm) do
        :gen_statm.call(fsm, :select_category)
    end

    def draw(fsm) do
        :gen_statm.call(fsm, :draw)
    end

    def vote(fsm) do
        :gen_statm.call(fsm, :vote)
    end

    ## states

    def initialized({:call, from}, :show_current_state, _state_data) do 
        {:keep_state_and_data, {:reply, from, :initialized}}
    end

    def initialized({:call, from}, :add_player, state_data) do
        {:next_state, :ready, state_data, {:reply, from, :ok}}
    end

    def initialized({:call, from}, _, _state_data) do
        {:keep_state_and_data, {:reply, from, :error}}
    end

    def ready({:call, from}, :add_player, _state_data) do 
        {:keep_state_and_data, {:reply, from, :ok}}
    end

    def ready({:call, from}, :start_game, state_data) do 
        {:next_state, :selecting_category, state_data, {:reply, from, :ok}}
    end

    def ready({:call, from}, :show_current_state, _state_data) do 
        {:keep_state_and_data, {:reply, from, :ready}}
    end

    def ready({:call, from}, _, _state_data) do
        {:keep_state_and_data, {:reply, from, :error}}
    end

    def selecting_category({:call, from}, :select_category, state_data) do 
        {:next_state, :drawing, state_data, {:reply, from, :ready}}
    end

    def selecting_category({:call, from}, _, _state_data) do
        {:keep_state_and_data, {:reply, from, :error}}
    end

    def drawing({:call, from}, :draw, _state_data) do 
        {:keep_state_and_data, {:reply, from, :ok}}
    end

    def game_over({:call, from}, :show_current_state, _state_data) do
        {:keep_state_and_data, {:reply, from, :game_over}}
    end

    def game_over({:call, from}, _, _state_data) do
        {:keep_state_and_data, {:reply, from, :error}}
    end

end