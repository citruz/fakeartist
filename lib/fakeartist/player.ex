defmodule Fakeartist.Player do
    defstruct name: :none, id: :none, question_master?: false, current_player?: false, fake?: false, color: :black

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

    def color(player) do
        Agent.get(player, fn state -> state.color end)
    end

    def set_color(player, color) do
        Agent.update(player, fn state -> Map.put(state, :color, color) end)
    end

    def to_string(player) do
        "(name:#{name(player)}, question_master:#{question_master?(player)})"
    end

    def props(player) do
        %{name: name(player), question_master: question_master?(player), fake_artist: fake?(player), color: color(player)}
    end
end