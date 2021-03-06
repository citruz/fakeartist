defmodule Fakeartist.Const do
  alias Fakeartist.Const

  def wxMIN_PLAYERS, do: 2
  def wxMAX_PLAYERS, do: length(Const.wxCOLORS())
  def wxDEFAULT_NUM_ROUNDS, do: 2

  def wxCOLORS,
    do: [
      :black,
      :blue,
      :red,
      :green,
      :chocolate,
      :purple,
      :violet,
      :orange,
      :gold,
      :limegreen,
      :olive,
      :turquoise,
      :teal,
      :deepskyblue,
      :slateblue,
      :deeppink,
      :burlywood
    ]

  def wxWORDLISTS, do: ["none", "de", "en"]
  def wxDEFAULT_WORDLIST, do: "none"
end
