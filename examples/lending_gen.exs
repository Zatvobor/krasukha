alias Krasukha.{LendingGen, HTTP}

Krasukha.start_lending!("BTC")
# the same as following:
{:ok, btc_lending} = LendingGen.start_link("BTC")

# fetch over HTTP using `{:ok, 200, response} = HTTP.PublicAPI.return_loan_orders/1`
:ok = GenServer.call(:btc_lending, :fetch_loan_orders)

# update loan orders every 60 seconds
params = %{server: :btc_lending, request: :fetch_loan_orders, every: 60}
IterativeGen.start_link(params, [:iterate])

# getting loan offers table
offers_tid = GenServer.call(:btc_lending, :offers_tid)
:ets.info(offers_tid)
:ok = GenServer.call(:btc_lending, :clean_loan_offers)


:ok = GenServer.stop(:btc_lending)
