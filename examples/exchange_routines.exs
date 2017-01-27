# init market monitor
{:ok, _pid} = Krasukha.start_wamp_connection
{:ok, _btc_xrp_market, _state} = Krasukha.start_market!("BTC_XRP")

# init secret agent
{:ok, agent} = Krasukha.start_secret_agent(key, secret)

# start routine :ask (buy), :bid (sell)
# You may optionally set "fillOrKill", "immediateOrCancel", "postOnly" to
# 1. A fill-or-kill order will either fill in its entirety or be completely aborted.
# An immediate-or-cancel order can be partially or completely filled, but any portion of the order that cannot be filled immediately will be canceled rather than left on the order book.
# A post-only order will only be placed if no portion of it fills immediately; this guarantees you will never pay the taker fee on any part of the order that fills.
params = %{fulfill_immediately: true, currency_pair: "BTC_XRP", stop_rate: 0.00000700, limit_amount: 15}
Krasukha.start_exchange_routine(agent, :buy_lowest, params)
params = %{sleep_time_inactive: 60, currency_pair: "BTC_XRP", stop_rate: 0.00000693, limit_amount: 15}
Krasukha.start_exchange_routine(agent, :sell_highest, params)

Krasukha.ExchangeRoutines.Supervisor.get_childrenspec
