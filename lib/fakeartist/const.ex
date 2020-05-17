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

  def wxWORDLIST,
    do: %{
      "ger" => %{
        "Beruf" => [
          "BäckerIn",
          "LehrerIn",
          "MalerIn"
        ],
        "TV" => [
          "Titanic",
          "Spiderman",
          "König der Löwen",
          "Star Wars",
          "Harry Potter",
          "Ironman",
          "James Bond",
          "Herr der Ringe",
          "Findet Nemo",
          "Fight Club",
          "Mission Impossible",
          "Game of Thrones"
        ]
      },
      "eng" => %{
        "Profession" => [
          "Baker",
          "Teacher",
          "Artist"
        ],
        "TV" => [
          "Titanic",
          "Spiderman",
          "The Lion King",
          "Star Wars",
          "Harry Potter",
          "Ironman",
          "James Bond",
          "Lord of the Rings",
          "Finding Nemo",
          "Fight Club",
          "Mission Impossible",
          "Game of Thrones"
        ]
      }
    }

  def wxWORDLISTS, do: ["none"] ++ Map.keys(Const.wxWORDLIST())
  def wxDEFAULT_WORDLIST, do: "none"
end
