# Fakeartist

This is a browser-based clone of the card game [A Fake Artist Goes to New York](https://boardgamegeek.com/boardgame/135779/fake-artist-goes-new-york) written in Elixir/Phoenix using LiveViews. It's collaborative drawing game which you can play online with your friends.

[Try it online](https://fakeartist.felixseele.de/)

## Features
- Create private games and share the link with friends
- Configurable game settings (number of rounds, mode)
- In-game chat
- Interactive voting
- Scoreboard
- Mobile compatible

## How to play
At the beginning of each game the Question Master chooses a category (e.g. Animals) and a subject (e.g. cat).

The Fake Artist is choosen randomly each game, but only he himself knows that it is him. All players see the category but the subject is hidden from the Fake Artist.

Now, the players take turns and each artist draws one mark to create the masterpiece. The Fake Artist needs to guess what the subject is and the other players must be careful not to reveal the subject too quickly.

After two rounds the players vote for who they believe the Fake Artist is.

## Tech Stack
- No database, all game data is stored in memory.
- (Almost) No JavaScript - thanks to [Phoenix LiveViews](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) there is only a minimal amount of custom JavaScript required for the drawing itself. The whole UI state is rendered server-side and transferred to the client via WebSockets.

## How to run
  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
