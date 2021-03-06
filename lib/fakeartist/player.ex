defmodule Fakeartist.Player do
  defstruct(
    name: :none,
    id: :none,
    question_master?: false,
    current_player?: false,
    fake?: false,
    color: :black,
    voted_for?: :none,
    score: 0,
    active?: true
  )

  alias Fakeartist.Player

  def start_link(name, id) do
    Agent.start_link(fn -> %Player{name: name, id: id} end)
  end

  def name(player) do
    Agent.get(player, fn state -> state.name end)
  end

  def id(player) do
    Agent.get(player, fn state -> state.id end)
  end

  def question_master?(player) do
    Agent.get(player, fn state -> state.question_master? end)
  end

  def set_question_master(player, bool) do
    Agent.update(player, fn state -> Map.put(state, :question_master?, bool) end)
  end

  def current_player?(player) do
    Agent.get(player, fn state -> state.current_player? end)
  end

  def set_current_player(player, bool) do
    Agent.update(player, fn state -> Map.put(state, :current_player?, bool) end)
  end

  def fake?(player) do
    Agent.get(player, fn state -> state.fake? end)
  end

  def set_fake(player, bool) do
    Agent.update(player, fn state -> Map.put(state, :fake?, bool) end)
  end

  def voted_for?(player) do
    Agent.get(player, fn state -> state.voted_for? end)
  end

  def vote_for(player, player_id) do
    Agent.update(player, fn state -> Map.put(state, :voted_for?, player_id) end)
  end

  def reset_vote(player) do
    Agent.update(player, fn state -> Map.put(state, :voted_for?, :none) end)
  end

  def color(player) do
    Agent.get(player, fn state -> state.color end)
  end

  def add_points(player, points) when is_integer(points) do
    Agent.update(player, fn state -> Map.put(state, :score, Map.get(state, :score) + points) end)
  end

  def score(player) do
    Agent.get(player, fn state -> state.score end)
  end

  def set_color(player, color) do
    Agent.update(player, fn state -> Map.put(state, :color, color) end)
  end

  def active?(player) do
    Agent.get(player, fn state -> state.active? end)
  end

  def set_inactive(player) do
    Agent.update(player, fn state -> Map.put(state, :active?, false) end)
  end

  def to_string(player) do
    "(name:#{name(player)}, question_master:#{question_master?(player)})"
  end

  def props(player) do
    %{
      name: name(player),
      question_master: question_master?(player),
      fake_artist: fake?(player),
      color: color(player)
    }
  end
end
