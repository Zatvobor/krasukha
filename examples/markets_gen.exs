alias Krasukha.{MarketsGen, WAMP, HTTP}

Krasukha.start_markets!()
# the same as following:
{:ok, markets} = MarketsGen.start_link()

# fetch over HTTP using `{:ok, 200, response} = HTTP.PublicAPI.return_ticker/0`
:ok = GenServer.call(:markets, :fetch_ticker)

# updating over WAMP
{:ok, wamp} = WAMP.connect!
{:ok, markets} = MarketsGen.start_link()
{:ok, subscription} = GenServer.call(:markets, :subscribe_ticker)
:ok = GenServer.call(:markets, :unsubscribe_ticker)
:ok = WAMP.disconnect!

# updating over HTTP
:ok = GenServer.call(:markets, {:update_ticker, [every: 60]})
:ok = GenServer.call(:markets, :stop_to_update_fetcher)


# getting ticker table
ticker_tid = GenServer.call(:markets, :ticker_tid)
:ets.info(ticker_tid)
:ok = GenServer.call(:markets, :clean_ticker)

:ok = GenServer.stop(:markets)
