defmodule Fakeartist.Player do
    defstruct name: :none, id: :none, question_master?: false, fake?: false, color: :black

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

    def is_question_master?(player) do
        Agent.get(player, fn state -> state.question_master? end)
    end

    def toggle_question_master(player) do
        Agent.update(player, fn state -> Map.put(state, :question_master?, !state.question_master?) end)
    end

    def set_question_master(player, bool) do
        Agent.update(player, fn state -> Map.put(state, :question_master?, bool) end)
    end

    def is_fake?(player) do
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
        "(name:#{name(player)}, question_master:#{is_question_master?(player)})"
    end

    def props(player) do
        %{name: name(player), question_master: is_question_master?(player), fake_artist: is_fake?(player), color: color(player)}
    end
end