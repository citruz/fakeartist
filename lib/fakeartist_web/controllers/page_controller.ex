defmodule FakeartistWeb.PageController do
  use FakeartistWeb, :controller

  def index(conn, params) do
    render(conn, "index.html", join_game_id: params["join"])
  end
end
