defmodule Fakeartist.Player do
    defstruct name: :none, question_master?: false

    alias Fakeartist.Player

    def start_link(name) do
        Agent.start_link(fn -> %Player{name: name} end)
    end

    def name(player) do
        Agent.get(player, fn state -> state.name end)
    end

    def question_master?(player) do
        Agent.get(player, fn state -> state.question_master? end)
    end

    def toggle_question_master(player) do
        Agent.update(player, fn state -> Map.put(state, :question_master?, !state.question_master?) end)
    end

    def to_string(player) do
        "(name:#{name(player)}, question_master:#{question_master?(player)})"
    end
        
end

    