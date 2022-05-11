FROM elixir:1.13.4

RUN mix local.hex --force \
  && mix archive.install hex phx_new --force \
  && mix local.rebar --force

COPY ./sample_app /app

WORKDIR /app

RUN mix deps.get

RUN mix compile.phoenix

EXPOSE 4000

CMD ["mix", "phx.server"]
