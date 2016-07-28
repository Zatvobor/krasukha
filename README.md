# Krasukha (рус. Красуха)

[![Build Status](https://travis-ci.org/Zatvobor/krasukha.svg?branch=master)](https://travis-ci.org/Zatvobor/krasukha) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Zatvobor/krasukha/blob/master/LICENSE)

## `Krasukha.OrderBookGen` API

```iex
{:ok, subscriber} = Krasukha.WAMP.connect!
:ok = Krasukha.WAMP.disconnect!
%{subscriber: subscriber} = Krasukha.WAMP.connection

{:ok, btc_sc} = Krasukha.MarketGen.start_link("BTC_SC")
:ok = GenServer.stop(btc_sc)

:ok = GenServer.call(btc_sc, {:fetch_order_book, [depth: 2]})
:ok = GenServer.call(btc_sc, :clean_order_book)

{:ok, subscription} = GenServer.call(btc_sc, :subscribe)
:ok = GenServer.call(btc_sc, :unsubscribe)
```

```iex
{:ok, btc_dash} = Krasukha.MarketGen.start_link("BTC_DASH")
:ok = GenServer.stop(btc_dash)
:ok = GenServer.call(btc_dash, {:fetch_order_book, [depth: 10]})
{:ok, _} = GenServer.call(btc_dash, :subscribe)
:ok = GenServer.call(btc_dash, :unsubscribe)
```

```iex
{:ok, markets} = Krasukha.MarketsGen.start_link()
:ok = GenServer.stop(markets)

{:ok, _} = GenServer.call(markets, :subscribe_ticker)
:ok = GenServer.call(markets, :unsubscribe_ticker)
:ok = GenServer.call(markets, :clean_ticker)
:ok = GenServer.call(markets, :fetch_ticker)
:ok = GenServer.stop(markets)
```
