defmodule Krasukha.HTTP.PrivateAPI do
  @moduledoc false

  alias Krasukha.{HTTP}

  @typedoc "Returns your balances sorted by account"
  @type account :: :all | :lending | :exchange | :margin


  @doc false
  def uri, do: %URI{ HTTP.uri | path: "/tradingApi" }

  @doc false
  def return_balances(agent) do
    HTTP.post("returnBalances", agent, uri)
  end

  @doc false
  def return_complete_balances(agent, params \\ [account: :all]) do
    HTTP.post("returnCompleteBalances", params, agent, uri)
  end

  @doc false
  def return_available_account_balances(agent, params \\ [account: :all]) do
    HTTP.post("returnAvailableAccountBalances", params, agent, uri)
  end

  @doc false
  def return_deposit_addresses(agent) do
    HTTP.post("returnDepositAddresses", agent, uri)
  end

  @doc false
  def create_loan_offer(agent, params \\ [currency: "SC", lendingRate: -1, amount: -1, duration: 2, autoRenew: 0]) do
    HTTP.post("createLoanOffer", params, agent, uri)
  end

  @doc false
  def cancel_loan_offer(agent, params \\ [orderNumber: -1]) do
    HTTP.post("cancelLoanOffer", params, agent, uri)
  end

  @doc false
  def return_open_loan_offers(agent) do
    HTTP.post("returnOpenLoanOffers", agent, uri)
  end

  @doc false
  def return_active_loans(agent) do
    HTTP.post("returnActiveLoans", agent, uri)
  end

  @doc false
  def toggle_auto_renew(agent, params \\ [orderNumber: -1]) do
    HTTP.post("toggleAutoRenew", params, agent, uri)
  end
end
