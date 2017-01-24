alias Krasukha.HTTP

defmodule Krasukha.HTTP.PrivateAPI do
  @moduledoc false

  @typedoc "Returns your balances sorted by account"
  @type account :: :all | :lending | :exchange | :margin

  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/tradingApi" }

  import Krasukha.SecretAgent, only: [to_pid: 1]

  @doc false
  def return_balances(agent) do
    HTTP.post("returnBalances", to_pid(agent), uri)
  end

  @doc false
  def return_complete_balances(agent, params \\ [account: :all]) do
    HTTP.post("returnCompleteBalances", params, to_pid(agent), uri)
  end

  @doc false
  def return_available_account_balances(agent, params \\ [account: :all]) do
    HTTP.post("returnAvailableAccountBalances", params, to_pid(agent), uri)
  end

  @doc false
  def return_deposit_addresses(agent) do
    HTTP.post("returnDepositAddresses", to_pid(agent), uri)
  end

  @doc false
  def create_loan_offer(agent, params \\ [currency: "SC", lendingRate: -1, amount: -1, duration: 2, autoRenew: 0]) do
    HTTP.post("createLoanOffer", params, to_pid(agent), uri)
  end

  @doc false
  def cancel_loan_offer(agent, params \\ [orderNumber: -1]) do
    HTTP.post("cancelLoanOffer", params, to_pid(agent), uri)
  end

  @doc false
  def return_open_loan_offers(agent) do
    HTTP.post("returnOpenLoanOffers", to_pid(agent), uri)
  end

  @doc false
  def return_active_loans(agent) do
    HTTP.post("returnActiveLoans", to_pid(agent), uri)
  end

  @doc false
  def return_lending_history(agent, params \\ [start: :timestamp, end: :timestamp, limit: -1]) do
    HTTP.post("returnLendingHistory", params, to_pid(agent), uri)
  end

  @doc false
  def toggle_auto_renew(agent, params \\ [orderNumber: -1]) do
    HTTP.post("toggleAutoRenew", params, to_pid(agent), uri)
  end

  @doc false
  def buy(agent, params \\ [currencyPair: "BTC_SC", rate: 0.00000023, amount: 400, fillOrKill: 0, immediateOrCancel: 0, postOnly: 0]) do
    HTTP.post("buy", params, to_pid(agent), uri)
  end

  @doc false
  def sell(agent, params \\ [currencyPair: "BTC_SC", rate: 0.00000023, amount: 400, fillOrKill: 0, immediateOrCancel: 0, postOnly: 0]) do
    HTTP.post("sell", params, to_pid(agent), uri)
  end
end
