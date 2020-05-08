defmodule FakeartistWeb.GameLive.Show do
  use FakeartistWeb, :live_view
  
  alias Fakeartist.{Game, Global, Player}
  alias FakeartistWeb.Endpoint

  defmodule CategoryInput do
    defstruct category: "", subject: ""
  end

  @impl true
  def mount(%{"id" => game_token}, %{"user_id" => user_id, "username" => username}, socket) 
  when user_id != nil and username !=nil do
    game = Global.get_game(game_token)
    if game == nil do
      socket = socket
      |> put_flash(:error, "Game does not exist")
      |> redirect(to: "/livegame") # TODO replace with /
      {:ok, socket}
    else
      # join game
      case Game.add_player(game, username, user_id) do
        {:ok, player} ->
          topic = "game:" <> game_token
          Endpoint.subscribe(topic)
          Endpoint.broadcast_from(self(), topic, "new_player", %{})
          socket = socket
          |> assign(:topic, topic)
          |> assign(:token, game_token)
          |> assign(:game, game)
          |> assign(:player, player)
          |> assign(:player_id, user_id)
          |> assign(:page_title, "Game")
          |> assign(:category_submit_enabled, false)
          |> assign(:changeset, category_input_changeset(%{}))
          |> update_game_state
          {:ok, socket}
        _ ->
          socket = socket
          |> put_flash(:error, "Error joining game")
          |> redirect(to: "/livegame") # TODO replace with /
          {:ok, socket}
      end    
    end
  end

  # unauthenticated
  def mount(%{"id" => game_token}, _, socket) do
    socket = socket
    |> put_flash(:info, "Please choose a username first")
    |> redirect(to: "/?join=" <> game_token)
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
    Enum.map(Game.get_players(game), fn p -> 
      %{
        name: Player.name(p),
        color: Player.color(p),
        fake?: Player.fake?(p),
        question_master?: Player.question_master?(p),
        current_player?: Player.current_player?(p),
      }
    end)
  end
  
  defp update_game_state(socket) do
    game = socket.assigns.game
    socket = socket
    |> assign(:players, get_players(game))
    |> assign(:state, Game.get_state(game))
    |> assign(:current_player, Game.get_current_player(game))
    |> assign(:category, Game.get_category(game))
    |> assign(:subject, Game.get_subject(game, socket.assigns.player_id))
    |> assign(:round, Game.get_round(game))
    |> assign(:num_rounds, Game.get_num_rounds(game))
    |> assign(:fake_player_name, fake_player_name(game))

    IO.puts("update_game_state:")
    IO.puts("game: #{inspect Game.props(game)}")
    IO.puts("players: #{inspect socket.assigns.players}")
    IO.puts("current_player: #{inspect socket.assigns.current_player}")
    socket
  end


  #
  # PubSub
  #

  @impl true
  def handle_info(%{event: "new_player"}, socket) do
    IO.puts("NEW PLAYER")
    socket = socket
    |> update_game_state
    {:noreply, socket}
  end

  def handle_info(%{event: "new_state"}, socket) do
    IO.puts("NEW STATE")
    socket = socket
    |> update_game_state
    {:noreply, socket}
  end

  def handle_info(event, socket) do
    IO.puts("handle_info: #{inspect event}")
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
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_category", %{"category_input" => %{"category" => category, "subject" => subject} = input}, socket) do
    changeset = input |> category_input_changeset()
    socket = socket 
    |> assign(:changeset, changeset)
    # TODO pretty sure this is not how you are supposed to do this :)
    |> assign(:category_submit_enabled, String.length(category) > 0 and String.length(subject) > 0)
    {:noreply, socket }
  end

  @impl true
  def handle_event("select_category", %{"category_input" => %{"category" => category, "subject" => subject}}, socket) do
    if String.length(category) > 0 and String.length(subject) > 0 do
      Game.select_category(socket.assigns.game, category, subject, socket.assigns.player_id)
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end
    {:noreply, socket }
  end
  
  def handle_event("next_turn", _params, socket) do
    if Game.next_turn(socket.assigns.game, socket.assigns.player_id) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end
    {:noreply, socket }
  end

  def handle_event("reveal", _params, socket) do
    if Game.reveal(socket.assigns.game, socket.assigns.player_id) == :ok do
      Endpoint.broadcast_from(self(), socket.assigns.topic, "new_state", %{})
      send(self(), %{event: "new_state"})
    end
    {:noreply, socket}
  end


  #
  # render helpers
  #
  defp render_state_div(assigns, :initialized) do
    ~L"""
    <div class="rounded-box">Waiting for other players...</div>
    """
  end

  defp render_state_div(assigns, state) when state in [:ready, :waiting_for_next_game] do
    if Player.question_master?(assigns.player) do
      ~L"""
        <button phx-click="start_game">Start Game</button>
      """
    else
      ~L"""
      <div class="rounded-box">Waiting for Question Master to start the game</div>
      """
    end
  end

  defp render_state_div(assigns, :selecting_category) do
    ~L"""
    <div class="rounded-box">
      <span><%= Player.name(Game.get_question_master(@game)) %></span> is selecting a category
    </div>
    """
  end

  defp render_state_div(%{current_player: current_player, player: player} = assigns, :drawing)
  when current_player == player  do
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
    if Player.question_master?(assigns.player) do
      ~L"""
        <div class="rounded-box">Voting</div>
        <button phx-click="reveal">Reveal</button>
      """
    else
      ~L"""
      <div class="rounded-box">Voting</div>
      """
    end
  end


  defp render_state_div(_assigns, other_state) do
    other_state
  end


  defp render_stats_div(assigns, state) when state in [:drawing, :voting, :waiting_for_next_game] do
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

  defp render_stats_div(_assigns, other_state), do: ""

  #
  # changeset helpers
  #
  defp category_input_changeset(params) do
    types = %{category: :string, subject: :string}

    {%CategoryInput{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end
end
  