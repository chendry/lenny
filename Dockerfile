FROM elixir:1.13.4

RUN mkdir /app
COPY . /app
WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile
RUN mix assets.deploy

CMD ["/usr/local/bin/mix", "phx.server"]
