defmodule FakeartistWeb.GameLive.Play do
  use FakeartistWeb, :live_view

  alias Fakeartist.{Game, Global, Player, Const}
  alias FakeartistWeb.Endpoint
  alias FakeartistWeb.GameLive.{VoteModal, ResultsModal}

  defmodule CategoryInput do
    defstruct category: "", subject: ""
  end

  defmodule ConfigInput do
    defstruct num_rounds: 2, wordlist: :none
  end

  @impl true
  def mount(%{"id" => game_token}, %{"user_id" => user_id, "username" => username}, socket)
      when user_id != nil and username != nil do
    game = Global.get_game(game_token)

    if game == nil do
      socket =
        socket
        |> put_flash(:error, "Game does not exist")
        |> redirect(to: "/")

      {:ok, socket}
    else
      # join game
      case Game.add_player(game, username, user_id) do
        {:ok, player} ->
          topic = "game:" <> game_token
          Endpoint.subscribe(topic)

          if socket.root_pid != nil do
            # since mount is called twice when you load the page, we check for root pid which
            # is only set the second time
            Endpoint.broadcast_from(self(), topic, "new_player", %{
              name: username,
              color: Player.color(player)
            })
          end

          # set initial values
          socket =
            socket
            |> assign(:topic, topic)
            |> assign(:token, game_token)
            |> assign(:game, game)
            |> assign(:player, player)
            |> assign(:player_id, user_id)
            |> assign(:page_title, "Game")
            |> assign(:category_submit_enabled, false)
            |> assign(:category_changeset, category_changeset(%{}))
            |> assign(:min_players, Const.wxMIN_PLAYERS())
            |> assign(:messages, [])
            |> assign(:chat_input, %{"message" => ""})
            |> assign(:results_shown, true)
            |> update_game_state

          {:ok, socket}

        {err, _} ->
          socket =
            socket
            |> put_flash(:error, "Error joining game: " <> Atom.to_string(err))
            |> redirect(to: "/")

          {:ok, socket}
      end
    end
  end

  # unauthenticated
  def mount(%{"id" => game_token}, _, socket) do
    socket =
      socket
      |> redirect(to: Routes.game_join_path(socket, :join, game_token))

    {:ok, socket}
  end

  defp fake_player_name(game) do
    player = Enum.find(Game.get_players(game), fn p -> Player.fake?(p) end)

    if player != nil do
      Player.name(player)
    else
      ""
    end
  end

  defp get_players(game) do
    # transfrom into struct so that the liveview diffing works
    players = Game.get_players(game)

    Enum.map(players, fn p ->
      %{
        name: Player.name(p),
        id: Player.id(p),
        color: Player.color(p),
        fake?: Player.fake?(p),
        question_master?: Player.question_master?(p),
        current_player?: Player.current_player?(p),
        can_control?: Game.can_control?(game, Player.id(p)),
        can_decide?: Game.can_decide?(game, Player.id(p)),
        voted_for: Player.voted_for?(p),
        score: Player.score(p)
      }
    end)
  end

  defp update_game_state(socket) do
    game = socket.assigns.game
    players = get_players(game)

    socket =
      socket
      |> assign(:players, players)
      |> assign(:num_players, length(players))
      |> assign(:state, Game.get_state(game))
      |> assign(:current_player, Game.get_current_player(game))
      |> assign(:can_control, Game.can_control?(game, socket.assigns.player_id))
      |> assign(:category, Game.get_category(game))
      |> assign(:subject, Game.get_subject(game, socket.assigns.player_id))
      |> assign(:round, Game.get_round(game))
      |> assign(:num_rounds, Game.get_num_rounds(game))
      |> assign(:fake_player_name, fake_player_name(game))
      |> assign(:controller_name, Player.name(Game.controller(game)))
      |> assign(:my_color, Player.color(socket.assigns.player))
      |> assign(:my_vote, Player.voted_for?(socket.assigns.player))
      |> assign(:guess_correct, Game.get_guess_correct(game))
      |> assign(:i_am_fake, Player.fake?(socket.assigns.player))
      |> assign(:fake_guess, Game.get_fake_guess(game))
      |> assign(:results, Game.get_results(game))
      |> assign(:results_shown, true)
      |> assign(
        :config_changeset,
        config_changeset(%{
          "num_rounds" => Game.get_num_rounds(game),
          "wordlist" => Game.get_wordlist(game)
        })
      )

    # IO.puts("update_game_state:")
    # IO.puts("game: #{inspect Game.props(game)}")
    # IO.puts("assigns: #{inspect socket.assigns}")
    # IO.puts("players: #{inspect socket.assigns.players}")
    # IO.puts("current_player: #{inspect socket.assigns.current_player}")
    # IO.puts("messages: #{inspect socket.assigns.messages}")
    socket
  end

  #
  # PubSub
  #

  @impl true
  def handle_info(%{event: "new_player", payload: %{name: player_name, color: color}}, socket) do
    IO.puts("new player")

    socket =
      socket
      |> assign(:messages, socket.assigns.messages ++ [{:join, color, player_name}])
      |> update_game_state

    {:noreply, socket}
  end

  def handle_info(%{event: "new_state"}, socket) do
    socket =
      socket
      |> update_game_state

    {:noreply, socket}
  end

  def handle_info(
        %{event: "new_message", payload: %{from: player_name, message: message}},
        socket
      ) do
    socket =
      socket
      |> assign(:messages, socket.assigns.messages ++ [{:message, player_name, message}])

    {:noreply, socket}
  end

  def handle_info(event, socket) do
    IO.puts("unhandled info: #{inspect(event)}")
    {:noreply, socket}
  end

  #
  # actions
  #
  @impl true
  def handle_event("start_game", _params, socket) do
    if Game.start_game(socket.assigns.game, socket.assigns.player_id) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})

      Endpoint.broadcast_from(self(), "draw:" <> socket.assigns.token, "clear", %{})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "validate_category",
        %{"category_input" => %{"category" => category, "subject" => subject} = input},
        socket
      ) do
    changeset = input |> category_changeset()

    socket =
      socket
      |> assign(:category_changeset, changeset)
      # TODO pretty sure this is not how you are supposed to do this :)
      |> assign(
        :category_submit_enabled,
        String.length(category) > 0 and String.length(subject) > 0
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "validate_config",
        %{"config_input" => %{"num_rounds" => num_rounds, "wordlist" => wordlist} = input},
        socket
      ) do
    num_rounds = String.to_integer(num_rounds)

    case Game.update_config(socket.assigns.game, socket.assigns.player_id, num_rounds, wordlist) do
      :ok ->
        # update changeset
        socket =
          socket
          |> assign(:config_changeset, input |> config_changeset())
          |> update_game_state

        Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
        send(self(), %{event: "new_state"})

        {:noreply, socket}

      err ->
        socket =
          socket
          |> put_flash(:error, "Error updating config: #{inspect(err)}")
          |> update_game_state

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "select_category",
        %{"category_input" => %{"category" => category, "subject" => subject}},
        socket
      ) do
    if String.length(category) > 0 and String.length(subject) > 0 do
      Game.select_category(socket.assigns.game, category, subject, socket.assigns.player_id)
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end

    {:noreply, socket}
  end

  def handle_event("next_turn", _params, socket) do
    if Game.next_turn(socket.assigns.game, socket.assigns.player_id) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end

    {:noreply, socket}
  end

  def handle_event("guess_correct", _params, socket) do
    if Game.set_guess_correct(socket.assigns.game, socket.assigns.player_id, true) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end

    {:noreply, socket}
  end

  def handle_event("guess_incorrect", _params, socket) do
    if Game.set_guess_correct(socket.assigns.game, socket.assigns.player_id, false) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end

    {:noreply, socket}
  end

  def handle_event("vote", %{"player-id" => player_id}, socket) do
    if Game.vote(socket.assigns.game, socket.assigns.player_id, player_id) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end

    {:noreply, socket}
  end

  def handle_event("chat_input_changed", %{"chat_input" => input}, socket) do
    {:noreply, socket |> assign(:chat_input, input)}
  end

  def handle_event("fake_guess_changed", %{"guess" => guess}, socket) do
    if Game.set_fake_guess(socket.assigns.game, socket.assigns.player_id, guess) == :ok do
      {:noreply, socket |> assign(:fake_guess, guess)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("send_message", %{"chat_input" => %{"message" => message}}, socket) do
    message = String.trim(message)

    if message != "" do
      message = %{from: Player.name(socket.assigns.player), message: message}
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_message", message)
      send(self(), %{event: "new_message", payload: message})
    end

    {:noreply, socket |> assign(:chat_input, %{"message" => ""})}
  end

  def handle_event("hide_results", _params, socket) do
    {:noreply, socket |> assign(:results_shown, false)}
  end

  #
  # render helpers
  #
  defp render_state_div(assigns, :initialized) do
    ~L"""
    <div class="rounded-box">Waiting for at least <%= @min_players - @num_players %> more players...</div>
    """
  end

  defp render_state_div(%{can_control: true} = assigns, state)
       when state in [:ready, :waiting_for_next_game] do
    ~L"""
      <button phx-click="start_game">Start Game</button>
    """
  end

  defp render_state_div(assigns, state) when state in [:ready, :waiting_for_next_game] do
    ~L"""
    <div class="rounded-box">Waiting for <%= @controller_name %> to start the game</div>
    """
  end

  defp render_state_div(assigns, :selecting_category) do
    ~L"""
    <div class="rounded-box">
      <span><%= Player.name(Game.get_question_master(assigns.game)) %></span> is selecting a category
    </div>
    """
  end

  defp render_state_div(%{current_player: current_player, player: player} = assigns, :drawing)
       when current_player == player do
    ~L"""
    <div class="rounded-box">Please draw and click Next when you are finished</div>
    <button phx-click="next_turn">Next</button>
    """
  end

  defp render_state_div(assigns, :drawing) do
    ~L"""
    <div class="rounded-box"><span><%= Player.name(@current_player) %></span> is drawing</div>
    """
  end

  defp render_state_div(assigns, :voting) do
    ~L"""
      <div class="rounded-box">Voting</div>
    """
  end

  defp render_state_div(_assigns, other_state) do
    other_state
  end

  defp render_stats_div(assigns, state)
       when state in [:drawing, :voting, :waiting_for_next_game] do
    ~L"""
    <div class="rounded-box">
      <b>Category:</b> <%= @category %><br />
      <b>Subject:</b> <%= @subject %><br />
      <b>Round:</b> <%= @round %>/<%= @num_rounds %><br />
      <%= if state == :waiting_for_next_game do %>
      <br />
      <b><%= @fake_player_name %></b> was the fake artist!<br />
      <% end %>
    </div>
    """
  end

  defp render_stats_div(_assigns, _other_state), do: ""

  # TODO move into its own component
  defp render_config_div(assigns, state) when state in [:initialized, :ready] do
    render_config_div_helper(assigns, Player.question_master?(assigns.player))
  end

  defp render_config_div(_assigns, _other_state), do: ""

  # question master
  defp render_config_div_helper(assigns, true) do
    ~L"""
    <div class="rounded-box">
      <h3>Game Settings</h3>
      <%= f = form_for @config_changeset, "#",
        id: "config-form",
        phx_submit: "start_game",
        phx_change: "validate_config" %>

        <div class="form-group">
          <%= label f, :num_rounds, "Number of rounds" %>
          <%= select f, :num_rounds, 1..5 %>
        </div>
        <div class="form-group">
          <%= label f, :wordlist %>
          <%= select f, :wordlist, ["None (Questionmaster)": "none", "Deutsch": "de", "English": "en"] %>
        </div>
      </form>
    </div>
    """
  end

  # regular player
  defp render_config_div_helper(assigns, false) do
    ~L"""
    <div class="rounded-box">
      <h3>Game Settings</h3>
      <%= f = form_for @config_changeset, "#",
        id: "config-form" %>

        <div class="form-group">
          <%= label f, :num_rounds, "Number of rounds" %>
          <%= select f, :num_rounds, 1..10, disabled: true %>
        </div>
        <div class="form-group">
          <%= label f, :wordlist %>
          <%= select f, :wordlist, ["None (Questionmaster)": "none", "Deutsch": "de", "English": "en"], disabled: true  %>
        </div>
      </form>
    </div>
    """
  end

  #
  # changeset helpers
  #
  defp category_changeset(params) do
    types = %{category: :string, subject: :string}

    {%CategoryInput{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end

  defp config_changeset(params) do
    types = %{num_rounds: :integer, wordlist: :string}

    {%ConfigInput{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end
end
