alias Krasukha.{MarketsGen, IterativeGen, WAMP, HTTP}

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
params = %{server: :markets, request: :fetch_ticker, every: 30, timeout: 10000}
IterativeGen.start_link(params, [:iterate])

# getting ticker table
ticker_tid = GenServer.call(:markets, :ticker_tid)
:ets.info(ticker_tid)
:ok = GenServer.call(:markets, :clean_ticker)

:ok = GenServer.stop(:markets)
