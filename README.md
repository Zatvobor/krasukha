# Krasukha (рус. Красуха)

[![Build Status](https://travis-ci.org/Zatvobor/krasukha.svg?branch=master)](https://travis-ci.org/Zatvobor/krasukha) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Zatvobor/krasukha/blob/master/LICENSE)

## Deploy a distributed node

It deploys an appliance by default (see details in `CMD` statement).

- `docker build -t krasukha:master .`
- `docker run -p 4369:4369 -dti --name=krasukha krasukha:master`

_Hint: you will be able to overwrite `CMD` statement right over `docker run` command._

Applies recent updates

- `docker exec krasukha sh -c 'git pull && mix compile'`
- `docker exec -ti krasukha bash`

_Hint: a `docker attach` is also available option._

## Manage your appliance

```
$ iex --name node1@127.0.0.1 --cookie krasukha -S mix
Erlang/OTP 19 [erts-8.0.2] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

iex(node1@127.0.0.1)> Node.ping(:"node@127.0.0.1")
:pong
```

# Enjoy
