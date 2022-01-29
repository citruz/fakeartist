VERSION 0.6
FROM elixir:1.13.2-alpine
WORKDIR /app

mix-base:
    RUN apk add --no-cache build-base
    RUN mix local.hex --force && \
        mix local.rebar --force

mix-deps:
    FROM +mix-base
    COPY mix.exs mix.lock .
    RUN mix deps.get
    SAVE ARTIFACT deps /deps

assets:
    FROM node:16
    COPY +mix-deps/deps deps
    COPY assets/package.json assets/package-lock.json ./assets/
    RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
    COPY --dir assets ./
    RUN npm run deploy --prefix ./assets
    SAVE ARTIFACT ./priv/static static

build:
    FROM +mix-base
    ENV MIX_ENV=prod
    ENV MIX_QUIET=y
    # compile deps first
    COPY +mix-deps/deps ./deps
    COPY mix.exs mix.lock .
    RUN mix compile
    # assemble app
    COPY +assets/static ./priv/static
    COPY --dir lib rel test ./
    COPY config/config.exs config/prod.exs config/runtime.exs ./config/
    RUN mix phx.digest
    # build final binary
    RUN mix do compile, release
    SAVE ARTIFACT _build/prod/rel/fakeartist fakeartist

build-img:
    FROM alpine:3.15
    RUN apk add --no-cache openssl ncurses-libs libstdc++ gcc
    WORKDIR /app
    RUN chown nobody:nobody /app
    USER nobody:nobody
    COPY --chown=nobody:nobody +build/fakeartist ./
    ENV HOME=/app
    EXPOSE 4000
    ENTRYPOINT ["bin/fakeartist", "start"]
    SAVE IMAGE --push citruz/fakeartist:latest

run-img:
    LOCALLY
    WITH DOCKER --load fakeartist:latest=+build-img
        RUN docker run --rm \
            -p 4000:4000 \
            -e SECRET_KEY_BASE=WPkhGNTmM0PFJxhov8K147S9dubVuOXqv0f4fyZYPz4FFtIF8HP8V44/5/BPFWLi \
            -e NO_CHECK_ORIGIN=y \
            fakeartist:latest
    END
