# Krasukha (рус. Красуха)

[![Build Status](https://travis-ci.org/Zatvobor/krasukha.svg?branch=master)](https://travis-ci.org/Zatvobor/krasukha) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Zatvobor/krasukha/blob/master/LICENSE)

## `Krasukha.OrderBookGen` API

```iex
{:ok, btc_sc} = Krasukha.OrderBookGen.start_link("BTC_SC")

# Loads the order book for a given market.
GenServer.call(btc_sc, {:fetch_order_book, [depth: 2]})
# Cleans the order book. Gets ready for loading from scratch.
GenServer.call(btc_sc, :clean_order_book)

GenServer.stop(btc_sc)
```
