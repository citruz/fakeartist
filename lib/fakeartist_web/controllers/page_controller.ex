defmodule FakeartistWeb.PageController do
  use FakeartistWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
