defmodule Fakeartist.Const do
    alias Fakeartist.Const

    def wxMIN_PLAYERS, do: 2
    def wxMAX_PLAYERS, do: length(Const.wxCOLORS)
    def wxDEFAULT_NUM_ROUNDS, do: 2
    def wxCOLORS, do: [:black, :blue, :red, :green, :chocolate, :purple, :violet, :orange, :pink]

    def wxWORDLIST, do: %{
        "ger" => %{
            "Beruf" => [
                "BäckerIn",
                "LehrerIn",
                "MalerIn"
            ]
        },
        "eng" => %{
            "Profession" => [
                "Baker",
                "Teacher",
                "Artist"
            ]
        }
    }

    def wxWORDLISTS, do: ["none"] ++ Map.keys(Const.wxWORDLIST)
    def wxDEFAULT_WORDLIST, do: "none"
end
