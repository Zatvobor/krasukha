alias Krasukha.{SecretAgent, LendingGen, LendingRoutines, HTTP}

# init lending market monitor
{:ok, xrp_lending} = LendingGen.start_link("XRP")
:ok = GenServer.call(:xrp_lending, {:update_loan_orders, [every: 60]})
:ok = GenServer.call(:xrp_lending, :stop_to_update_loan_orders)

# init secret agent
{:ok, agent} = Krasukha.start_secret_agent(key, secret)
account_balance = SecretAgent.account_balance!(agent, :lending)

# sleep between inactive iterations, time in seconds
state = %{fulfill_immediately: true, sleep_time_inactive: 60, currency: "XRP", gap_top_position: 10}
main_routine = LendingRoutines.start(agent, :available_balance_to_gap_position, state)

#start routine w/ out `update_loan_orders`
{:ok, xrp_lending} = LendingGen.start_link("XRP")
state = %{fetch_loan_orders: true, sleep_time_inactive: 60, currency: "XRP", gap_top_position: 10}
main_routine = LendingRoutines.start(agent, :available_balance_to_gap_position, state)

# stop routine
Process.exit(main_routine, :normal)

{:ok, xrp_lending} = Krasukha.start_lending("XRP")
{:ok, available_balance_to_gap_position} = Krasukha.start_lending_routine(agent, :available_balance_to_gap_position, %{currency: "XRP", fetch_loan_orders: true})
