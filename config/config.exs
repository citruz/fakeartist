# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :fakeartist, FakeartistWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4hzag23NxjiYS+tui1VjWGYxvUunryaTqnzJM9tkdyXcFY6MHY+/E/jfBgOnnP/9",
  render_errors: [view: FakeartistWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Fakeartist.PubSub,
  live_view: [signing_salt: "uRpxd/V5"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
