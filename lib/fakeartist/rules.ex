defmodule Fakeartist.Rules do
  @behaviour :gen_statem
  defstruct num_players: 1, turn: 1, round: 1, num_rounds: 0, has_question_master: true

  alias Fakeartist.{Rules, Const}

  def start_link(num_rounds) when is_integer(num_rounds) do
    :gen_statem.start_link(__MODULE__, {:initialized, num_rounds}, [])
  end

  def init({_, num_rounds}) do
    {:ok, :initialized, %Rules{num_rounds: num_rounds}}
  end

  def callback_mode(), do: :state_functions

  def code_change(_vsn, state_name, state_data, _extra) do
    {:ok, state_name, state_data}
  end

  def terminate(_reason, _state, _data), do: :nothing

  ## getter

  def show_current_state(fsm) do
    :gen_statem.call(fsm, :show_current_state)
  end

  def get_round(fsm) do
    :gen_statem.call(fsm, :get_round)
  end

  def get_turn(fsm) do
    :gen_statem.call(fsm, :get_turn)
  end

  ## transitions

  def add_player(fsm) do
    :gen_statem.call(fsm, :add_player)
  end

  def update_config(fsm, num_rounds, has_question_master) when is_boolean(has_question_master) do
    :gen_statem.call(fsm, {:update_config, num_rounds, has_question_master})
  end

  def start_game(fsm) do
    :gen_statem.call(fsm, :start_game)
  end

  def select_category(fsm) do
    :gen_statem.call(fsm, :select_category)
  end

  def next_turn(fsm) do
    :gen_statem.call(fsm, :next_turn)
  end

  def vote(fsm) do
    :gen_statem.call(fsm, :vote)
  end

  def reveal(fsm) do
    :gen_statem.call(fsm, :reveal)
  end

  ## states

  def initialized({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :initialized}}
  end

  def initialized({:call, from}, :add_player, state_data) do
    num_players = state_data.num_players + 1
    state_data = Map.put(state_data, :num_players, num_players)

    if num_players >= Const.wxMIN_PLAYERS() do
      {:next_state, :ready, state_data, {:reply, from, :ok}}
    else
      {:keep_state, state_data, {:reply, from, :ok}}
    end
  end

  def initialized({:call, from}, {:update_config, num_rounds, has_question_master}, state_data)
      when num_rounds > 0 do
    state_data = Map.put(state_data, :num_rounds, num_rounds)
    state_data = Map.put(state_data, :has_question_master, has_question_master)
    {:keep_state, state_data, {:reply, from, :ok}}
  end

  def initialized({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def initialized({:call, from}, :get_turn, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.turn}}
  end

  def initialized({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def ready({:call, from}, :add_player, state_data) do
    if state_data.num_players == Const.wxMAX_PLAYERS() do
      # deny adding more players
      {:keep_state_and_data, {:reply, from, :max_players_reached}}
    else
      state_data = Map.put(state_data, :num_players, state_data.num_players + 1)
      {:keep_state, state_data, {:reply, from, :ok}}
    end
  end

  def ready({:call, from}, {:update_config, num_rounds, has_question_master}, state_data)
      when num_rounds > 0 do
    state_data =
      state_data
      |> Map.put(:num_rounds, num_rounds)
      |> Map.put(:has_question_master, has_question_master)

    {:keep_state, state_data, {:reply, from, :ok}}
  end

  def ready({:call, from}, :start_game, %Rules{has_question_master: false} = state_data) do
    {:next_state, :drawing, state_data, {:reply, from, :ok}}
  end

  def ready({:call, from}, :start_game, state_data) do
    {:next_state, :selecting_category, state_data, {:reply, from, :ok}}
  end

  def ready({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :ready}}
  end

  def ready({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def ready({:call, from}, :get_turn, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.turn}}
  end

  def ready({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def selecting_category({:call, from}, :select_category, state_data) do
    {:next_state, :drawing, state_data, {:reply, from, :ok}}
  end

  def selecting_category({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def selecting_category({:call, from}, :get_turn, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.turn}}
  end

  def selecting_category({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :selecting_category}}
  end

  def selecting_category({:call, from}, :add_player, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_already_started}}
  end

  def selecting_category({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def drawing(
        {:call, from},
        :next_turn,
        %Rules{
          turn: turn,
          num_players: num_players,
          round: round,
          num_rounds: num_rounds,
          has_question_master: has_question_master
        } = state_data
      )
      when ((not has_question_master and turn == num_players) or
              (has_question_master and turn == num_players - 1)) and
             round == num_rounds do
    # reached end
    IO.puts("reached end: #{inspect(state_data)}")
    {:next_state, :voting, state_data, {:reply, from, :ok}}
  end

  def drawing(
        {:call, from},
        :next_turn,
        %Rules{
          turn: turn,
          num_players: num_players,
          round: round,
          num_rounds: num_rounds,
          has_question_master: has_question_master
        } = state_data
      )
      when (not has_question_master and turn == num_players) or
             (has_question_master and turn == num_players - 1) do
    # next round
    IO.puts("next round: #{inspect(state_data)}")
    state_data = Map.put(state_data, :turn, 1)
    state_data = Map.put(state_data, :round, state_data.round + 1)
    IO.puts("next round after: #{inspect(state_data)}")
    {:keep_state, state_data, {:reply, from, :ok}}
  end

  def drawing({:call, from}, :next_turn, state_data) do
    # next turn
    IO.puts("next turn: #{inspect(state_data)}")
    state_data = Map.put(state_data, :turn, state_data.turn + 1)
    IO.puts("next turn after: #{inspect(state_data)}")
    {:keep_state, state_data, {:reply, from, :ok}}
  end

  def drawing({:call, from}, :show_current_state, state_data) do
    {:keep_state_and_data, {:reply, from, :drawing}}
  end

  def drawing({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def drawing({:call, from}, :get_turn, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.turn}}
  end

  def drawing({:call, from}, :add_player, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_already_started}}
  end

  def drawing({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def voting({:call, from}, :vote, state_data) do
    {:keep_state_and_data, {:reply, from, :ok}}
  end

  def voting({:call, from}, :reveal, state_data) do
    {:next_state, :waiting_for_next_game, state_data, {:reply, from, :ok}}
  end

  def voting({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :voting}}
  end

  def voting({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def voting({:call, from}, :add_player, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_already_started}}
  end

  def voting({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def waiting_for_next_game(
        {:call, from},
        :start_game,
        %Rules{has_question_master: false} = state_data
      ) do
    state_data = Map.put(state_data, :round, 1)
    state_data = Map.put(state_data, :turn, 1)
    {:next_state, :drawing, state_data, {:reply, from, :ok}}
  end

  def waiting_for_next_game({:call, from}, :start_game, state_data) do
    state_data = Map.put(state_data, :round, 1)
    state_data = Map.put(state_data, :turn, 1)
    {:next_state, :selecting_category, state_data, {:reply, from, :ok}}
  end

  def waiting_for_next_game({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :waiting_for_next_game}}
  end

  def waiting_for_next_game({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def waiting_for_next_game({:call, from}, :add_player, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_already_started}}
  end

  def waiting_for_next_game({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end

  def game_over({:call, from}, :show_current_state, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_over}}
  end

  def game_over({:call, from}, :get_round, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.round}}
  end

  def game_over({:call, from}, :get_turn, state_data) do
    {:keep_state_and_data, {:reply, from, state_data.turn}}
  end

  def game_over({:call, from}, :add_player, _state_data) do
    {:keep_state_and_data, {:reply, from, :game_already_started}}
  end

  def game_over({:call, from}, _, _state_data) do
    {:keep_state_and_data, {:reply, from, :error}}
  end
end
