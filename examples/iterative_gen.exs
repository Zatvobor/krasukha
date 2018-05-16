alias Krasukha.{MarketsGen, IterativeGen}

Krasukha.start_markets()

params = %{server: :markets, request: :fetch_ticker, every: 60}
params = %{server: :btc_dash_market, request: :shrink_order_books, every: 60}
Krasukha.start_iterator(params, [:iterate])

Krasukha.start_iterator(params)
GenServer.call(pid("0.0.0"), :start)
