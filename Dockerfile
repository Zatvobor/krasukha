FROM elixir:1.3.4
MAINTAINER Zatvobor <http://zatvobor.github.io>

RUN mix do local.hex --force, local.rebar --force

RUN apt-get install -y git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git clone https://github.com/Zatvobor/krasukha.git \
  && cd krasukha \
  && mix do deps.get, compile \
  && mix test

EXPOSE 4369

WORKDIR /krasukha
CMD iex --name node@127.0.0.1 --cookie krasukha --no-halt -S mix
