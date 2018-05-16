# Starts market monitor as stadalone gen server
{:ok, _btc_sc_market} = Krasukha.MarketGen.start_link("BTC_SC")
# load order books from HTTP API
:ok = GenServer.call(:btc_sc_market, {:fetch_order_books, [depth: 10]})
# subscribe for updates over WAMP
{:ok, _pid} = Krasukha.start_wamp_connection
{:ok, subscription} = GenServer.call(:btc_sc_market, :subscribe)
# subscribe for updates over HTTP
params = %{server: :btc_dash_market, request: :shrink_order_books, timeout: 10000, every: 40}
Krasukha.IterativeGen.start_link(params, [:iterate])

# Init market monitor over OTP
{:ok, _pid} = Krasukha.start_wamp_connection
{:ok, _btc_sc_market} = Krasukha.start_market!("BTC_SC")
# Stop market monitor
:ok = GenServer.stop(:btc_sc_market, :normal)
