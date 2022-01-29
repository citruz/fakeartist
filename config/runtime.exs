import Config

# The secret key base is used to sign/encrypt cookies and other secrets.
# A default value is used in config/dev.exs and config/test.exs but you
# want to use a different value for prod and you most likely don't want
# to check this value into version control, so we use an environment
# variable instead.
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing
    """

# port to listen on
port = String.to_integer(System.get_env("PORT") || "4000")

# external and host for building URLs
ext_port = String.to_integer(System.get_env("EXT_PORT") || Integer.to_string(port))
ext_host = System.get_env("EXT_HOST") || "localhost"
origin = if System.get_env("NO_CHECK_ORIGIN"), do: false, else: ["https://#{ext_host}"]

config :fakeartist, FakeartistWeb.Endpoint,
  url: [host: ext_host, port: ext_port],
  http: [port: port],
  secret_key_base: secret_key_base,
  check_origin: origin
