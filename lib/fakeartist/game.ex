defmodule Fakeartist.Game do
    use GenServer

    alias Fakeartist.{Game, Player, Rules, Const}

    defstruct(
        players: [],
        fsm: :none,
        category: :none,
        subject: :none,
        num_rounds: Const.wxDEFAULT_NUM_ROUNDS,
        i_current_player: :none,
        i_question_master: :none,
        i_fake: :none,
        wordlist: Const.wxDEFAULT_WORDLIST
    )


    def start_link(name, player_id) when not is_nil name do
        GenServer.start_link(__MODULE__, {name, player_id})
    end

    def init({name, player_id}) do
        {:ok, player} = Player.start_link(name, player_id)
        Player.set_question_master(player, true)
        {:ok, fsm} = Rules.start_link(Const.wxDEFAULT_NUM_ROUNDS)
        {:ok, %Game{players: [player], fsm: fsm}}
    end

    def update_config(pid, player, num_rounds, wordlist) when is_integer num_rounds do
        if num_rounds >= 1
                and wordlist in Const.wxWORDLISTS
                and Game.is_question_master?(pid, player) do
            GenServer.call(pid, {:update_config, num_rounds, wordlist})
        else
            {:error, :not_allowed}
        end
    end

    def update_config(pid, _, _, _) do
        {:error, :invalid_config}
    end

    def get_players(pid) do
        GenServer.call(pid, :get_players)
    end

    def get_player(pid, id) do
        GenServer.call(pid, {:get_player, id})
    end

    def creator?(pid, player) do
        Game.get_player_idx(pid, player) == 0
    end

    def get_creator(pid) do
        GenServer.call(pid, :get_creator)
    end

    def can_control?(pid, player) do
        (Game.has_question_master?(pid) and Game.is_question_master?(pid, player)) or Game.creator?(pid, player)
    end

    def controller(pid) do
        if Game.has_question_master?(pid) do
            Game.get_question_master(pid)
        else
            Game.get_creator(pid)
        end
    end

    def get_player_idx(pid, id) do
        Game.get_players(pid) |> Enum.find_index(fn p -> Player.id(p) == id end)
    end

    def get_current_player(pid) do
        GenServer.call(pid, :get_current_player)
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
        if Game.can_control?(pid, player) do
            GenServer.call(pid, :start_game)
        else
            :error
        end
    end

    def reveal(pid, player) do
        if Game.can_control?(pid, player) do
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
        |> Player.question_master?
    end

    def get_question_master(pid) do
        GenServer.call(pid, :get_question_master)
    end

    def has_question_master?(pid) do
        GenServer.call(pid, :has_question_master)
    end

    def get_state(pid) do
        GenServer.call(pid, :get_state)
    end

    def get_round(pid) do
        GenServer.call(pid, :get_round)
    end

    def get_num_rounds(pid) do
        GenServer.call(pid, :get_num_rounds)
    end

    def select_category(pid, category, subject, player) do
        if Game.is_question_master?(pid, player) do
            GenServer.call(pid, {:select_category, category, subject})
        else
            :error
        end
    end

    def get_wordlist(pid) do
        GenServer.call(pid, :get_wordlist)
    end

    def get_category(pid) do
        GenServer.call(pid, :get_category)
    end

    def get_subject(pid, player_id) do
        player = Game.get_player(pid, player_id)
        state = Game.get_state(pid)
        if Player.fake?(player) and state != :waiting_for_next_game do
            "X"
        else
            GenServer.call(pid, :get_subject)
        end
    end

    def next_turn(pid, player) do
        GenServer.call(pid, {:next_turn, player})
    end

    def vote(pid, voter, votee) do
        GenServer.call(pid, {:vote, voter, votee})
    end

    #
    # helpers
    #
    defp get_next_player(state) do
        #IO.puts("get_next_player: #{inspect state}")
        num_players = length(state.players)
        idx = rem(state.i_current_player + 1, num_players)
        if idx == state.i_question_master do
            rem(idx + 1, num_players)
        else
            idx
        end
    end

    defp update_players(state) do
        #IO.puts("update_players: #{inspect state}")
        state.players
        |> Enum.with_index
        |> Enum.each(fn {p, i} -> 
            Player.set_current_player(p, state.i_current_player == i)
            Player.set_fake(p, state.i_fake == i)
            Player.set_question_master(p, state.i_question_master == i)
        end)
        state
    end


    #
    # handlers
    #
    def handle_call({:get_player, id}, _from, state) do
        player = Enum.find(state.players, fn(player) ->
            Player.id(player) == id
        end
        )
        {:reply, player, state}
    end

    def handle_call(:get_creator, _from, state) do
        {:reply, Enum.at(state.players, 0), state}
    end

    def handle_call(:props, _from, state) do
        players = Enum.map(state.players, fn p -> Player.props(p) end)
        game_state = Rules.show_current_state(state.fsm)
        props = %{
            players: players,
            state: Atom.to_string(game_state),
            category: state.category,
            i_current_player: state.i_current_player,
            round: Rules.get_round(state.fsm),
            num_rounds: state.num_rounds,
            wordlist: state.wordlist
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

    defp get_category_and_subject(%Game{wordlist: wordlist} = state) when wordlist == "none" do
        state
        |> Map.put(:category, :none)
        |> Map.put(:subject, :none)
    end

    defp get_category_and_subject(%Game{wordlist: lang} = state) do
        categories = Map.keys(Const.wxWORDLIST[lang])
        category = Enum.at(categories, :rand.uniform(length(categories)) - 1)
        subjects = Const.wxWORDLIST[lang][category]
        subject = Enum.at(subjects, :rand.uniform(length(subjects)) - 1)
        state
        |> Map.put(:category, category)
        |> Map.put(:subject, subject)
    end

    def handle_call({:update_config, num_rounds, wordlist}, _from, state) do
        case Rules.update_config(state.fsm, num_rounds, wordlist == "none") do
            :ok ->
                state = state
                |> Map.put(:wordlist, wordlist)
                |> Map.put(:num_rounds, num_rounds)
                {:reply, :ok, state}
            reply ->
                {:reply, reply, state}
        end
    end

    defp get_next_question_master(%Game{wordlist: wordlist}) when wordlist != "none" do
        # no question master
        :none
    end

    defp get_next_question_master(state) do
        # get next question master
        num_players = length(state.players)
        case state.i_question_master do
            # first round
            :none -> 0
            other -> rem(other + 1, num_players)
        end
    end

    def handle_call(:start_game, _from, state) do
        case Rules.start_game(state.fsm) do
            :ok ->
                num_players = length(state.players)
                # select next qm
                i_qm = get_next_question_master(state)
                # select first player
                i_cur_player = case i_qm do
                    :none -> 
                        # if there is no question master, choose random player
                        :rand.uniform(num_players) - 1
                    i_qm ->
                        # first player is the one after question master
                        rem(i_qm + 1, num_players)
                    end
                # randomly choose fake artist
                i_fake = case i_qm do
                    :none ->
                        # no question master -> random player is fake
                        :rand.uniform(num_players) - 1
                    i_qm ->
                        # random player which is not question master
                        rem(i_qm + :rand.uniform(num_players - 1), num_players)
                    end
                state = state
                |> Map.put(:i_question_master, i_qm)
                |> Map.put(:i_current_player, i_cur_player)
                |> Map.put(:i_fake, i_fake)
                |> update_players
                |> get_category_and_subject

                # reset player votes
                Enum.each(state.players, fn p -> Player.reset_vote(p) end)

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
                if player_idx == state.i_current_player do
                    {:reply, Player.color(player), state}
                else
                    {:reply, false, state}
                end
            _ ->
                {:reply, false, state}
        end
    end

    def handle_call(:get_question_master, _from, state) do
        player = Enum.find(state.players, fn player -> Player.question_master?(player) end)
        {:reply, player, state}
    end

    def handle_call(:has_question_master, _from, state) do
        {:reply, state.wordlist == "none", state}
    end

    def handle_call(:get_state, _from, state) do
        {:reply, Rules.show_current_state(state.fsm), state}
    end

    def handle_call(:get_round, _from, state) do
        {:reply, Rules.get_round(state.fsm), state}
    end

    def handle_call(:get_num_rounds, _from, state) do
        {:reply, state.num_rounds, state}
    end

    def handle_call({:select_category, category, subject}, _from, state) do
        case Rules.select_category(state.fsm) do
            :ok ->
                state = state |> Map.put(:category, category) |> Map.put(:subject, subject)
                {:reply, :ok, state}
            reply ->
                {:reply, reply, state}
        end
    end

    def handle_call(:get_players, _from, state) do
        {:reply, state.players, state}
    end

    def handle_call(:get_current_player, _from, %{i_current_player: i_current_player} = state)
    when i_current_player == :none do
        {:reply, nil, state}
    end

    def handle_call(:get_current_player, _from, state) do
        {:reply, Enum.at(state.players, state.i_current_player), state}
    end

    def handle_call(:get_wordlist, _from, state) do
        {:reply, state.wordlist, state}
    end

    def handle_call(:get_category, _from, state) do
        {:reply, state.category, state}
    end

    def handle_call(:get_subject, _from, state) do
        {:reply, state.subject, state}
    end

    def handle_call({:next_turn, player}, _from, state) do
        player_idx = state.players |> Enum.find_index(fn p -> Player.id(p) == player end)

        if player_idx == state.i_current_player do
            case Rules.next_turn(state.fsm) do
            :ok ->
                state = state 
                |> Map.put(:i_current_player, get_next_player(state))
                |> update_players
                {:reply, :ok, state}
            reply ->
                {:reply, reply, state}
            end
        else
            {:reply, :error, state}
        end
    end

    def handle_call({:vote, voter, votee}, _from, state) do
        voter_pid = Enum.find(state.players, fn p -> Player.id(p) == voter end)
        votee_pid = Enum.find(state.players, fn p -> Player.id(p) == votee end)

        if voter_pid != nil and votee_pid != nil do
            case Rules.vote(state.fsm) do
            :ok ->
                Player.vote_for(voter_pid, votee)
                {:reply, :ok, state}
            reply ->
                {:reply, reply, state}
            end
        else
            {:reply, :unknown_player, state}
        end
    end 

end
