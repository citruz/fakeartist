defmodule Fakeartist.Game do
    use GenServer

    defstruct players: [], fsm: :none, category: :none, subject: :none, current_player: :none, num_rounds: :none, i_question_master: :none

    alias Fakeartist.{Game, Player, Rules, Const}

    def start_link(name, player_id, num_rounds) when (not is_nil name) and (num_rounds > 0) do
        GenServer.start_link(__MODULE__, {name, player_id, num_rounds})
    end

    def terminate(reason, state) do 
        IO.puts("TERMINATEEEE #{inspect reason} #{inspect state}")
    end

    def init({name, player_id, num_rounds}) do
        {:ok, player} = Player.start_link(name, player_id)
        Player.set_question_master(player, true)
        {:ok, fsm} = Rules.start_link(num_rounds)
        {:ok, %Game{players: [player], fsm: fsm, num_rounds: num_rounds}}
    end

    def get_players(pid) do
        GenServer.call(pid, :get_players)
    end

    def get_player(pid, id) do
        GenServer.call(pid, {:get_player, id})
    end

    def get_player_idx(pid, id) do
        Game.get_players(pid) |> Enum.find_index(fn p -> Player.id(p) == id end)
    end

    def get_current_player(pid) do
        GenServer.call(pid, :props)
    end

    def props(pid) do
        GenServer.call(pid, :props)
    end

    def add_player(pid, name, id) when name != nil do
        case Game.get_player(pid, id) do
            nil ->
                GenServer.call(pid, {:add_player, name, id})
            player ->
                {:ok, player}
        end
    end

    def start_game(pid, player) do
        if Game.is_question_master?(pid, player) do
            GenServer.call(pid, :start_game)
        else
            :error
        end
    end

    def reveal(pid, player) do
        if Game.is_question_master?(pid, player) do
            GenServer.call(pid, :reveal)
        else
            :error
        end
    end

    def can_draw?(pid, player) do
        GenServer.call(pid, {:can_draw?, player})
    end

    def is_question_master?(pid, player) do
        Game.get_player(pid, player)
        |> Player.is_question_master?
    end

    def get_question_master(pid) do
        GenServer.call(pid, :get_question_master)
    end

    def get_state(pid) do
        GenServer.call(pid, :get_state)
    end

    def select_category(pid, category, subject, player) do
        if Game.is_question_master?(pid, player) do
            GenServer.call(pid, {:select_category, category, subject})
        else
            :error
        end
    end

    def get_category(pid) do
        GenServer.call(pid, :get_category)
    end

    def get_subject(pid) do
        GenServer.call(pid, :get_subject)
    end

    def next_turn(pid, player) do
        GenServer.call(pid, {:next_turn, player})
    end

    defp get_next_player(state) do
        IO.puts("get_next_player: #{inspect state}")
        num_players = length(state.players)
        # first round is a special case
        next_player = if state.current_player == :none do 
            0
        else
            rem(state.current_player + 1, num_players)
        end

        if next_player == state.i_question_master do
            rem(next_player + 1, num_players)
        else
            next_player
        end
    end


    def handle_call({:get_player, id}, _from, state) do
        player = Enum.find(state.players, fn(player) ->
            Player.id(player) == id
        end
        )
        {:reply, player, state}
    end

    def handle_call(:props, _from, state) do
        players = Enum.map(state.players, fn p -> Player.props(p) end)
        game_state = Rules.show_current_state(state.fsm)
        props = %{
            players: players,
            state: Atom.to_string(game_state),
            category: state.category,
            current_player: state.current_player,
            round: Rules.get_round(state.fsm),
            num_rounds: state.num_rounds,
        }
        {:reply, props, state}
    end

    def handle_call({:add_player, name, id}, _from, state) do
        case Rules.add_player(state.fsm) do
            :ok ->
                {:ok, player} = Player.start_link(name, id)
                Player.set_color(player, Enum.at(Const.wxCOLORS, length(state.players) + 1))
                state = Map.put(state, :players, state.players ++ [player])
                {:reply, {:ok, player}, state}
            reply ->
                {:reply, {reply, nil}, state}
        end
    end

    def handle_call(:start_game, _from, state) do
        case Rules.start_game(state.fsm) do
            :ok ->
                num_players = length(state.players)
                last_idx = num_players - 1
                # select next qm
                i_qm = case state.i_question_master do
                    # first round
                    :none -> 0
                    ^last_idx -> 0
                    other -> other + 1
                end
                # randomly choose fake artist
                # random number is between 1 and num_players - 1
                i_fake = rem(i_qm + :rand.uniform(num_players - 1), num_players)
                state.players
                |> Enum.with_index
                |> Enum.each(fn {p, i} -> 
                    case i do
                        ^i_qm -> 
                            Player.set_question_master(p, true)
                            Player.set_fake(p, false)
                        ^i_fake ->
                            Player.set_question_master(p, false)
                            Player.set_fake(p, true)
                        _ ->
                            Player.set_question_master(p, false)
                            Player.set_fake(p, false)
                    end
                end)
                state = Map.put(state, :i_question_master, i_qm)
                state = Map.put(state, :current_player, i_qm)
                state = Map.put(state, :current_player, get_next_player(state))
                {:reply, :ok, state}
            reply ->
                {:reply, reply, state}
        end
    end

    def handle_call(:reveal, _from, state) do
        {:reply, Rules.reveal(state.fsm), state}
    end

    def handle_call({:can_draw?, player}, _from, state) do
        case Rules.show_current_state(state.fsm) do
            :drawing ->
                {player, player_idx} = state.players
                |> Enum.with_index
                |> Enum.find(fn {p, _i} -> Player.id(p) == player end)
                if player_idx == state.current_player do
                    {:reply, Player.color(player), state}
                else
                    {:reply, false, state}
                end
            _ ->
                {:reply, false, state}
        end
    end

    def handle_call(:get_question_master, _from, state) do
        player = Enum.find(state.players, fn player -> Player.is_question_master?(player) end)
        {:reply, player, state}
    end

    def handle_call(:get_state, _from, state) do
        {:reply, Rules.show_current_state(state.fsm), state}
    end

    def handle_call({:select_category, category, subject}, _from, state) do
        case Rules.select_category(state.fsm) do
            :ok ->
                state = state |> Map.put(:category, category) |> Map.put(:subject, subject)
                IO.puts("#inspect{state}")
                {:reply, :ok, state}
            reply ->
                IO.puts("got reply #inspect{state} " <> Atom.to_string(reply))
                {:reply, reply, state}
        end
    end

    def handle_call(:get_players, _from, state) do
        {:reply, state.players, state}
    end

    def handle_call(:get_current_player, _from, state) do
        {:reply, state.players[state.current_player], state}
    end

    def handle_call(:get_category, _from, state) do
        {:reply, state.category, state}
    end

    def handle_call(:get_subject, _from, state) do
        {:reply, state.subject, state}
    end

    def handle_call({:next_turn, player}, _from, state) do
        player_idx = state.players |> Enum.find_index(fn p -> Player.id(p) == player end)

        if player_idx == state.current_player do
            case Rules.next_turn(state.fsm) do
                :ok ->
                    state = Map.put(state, :current_player, get_next_player(state))
                    {:reply, :ok, state}
                reply ->
                    {:reply, reply, state}
            end
        else
            {:reply, :error, state}
        end
    end

end
