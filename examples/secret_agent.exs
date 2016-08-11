alias Krasukha.{SecretAgent}

{:ok, agent} = Krasukha.start_secret_agent(key, secret)

lending_balance = SecretAgent.account_balance!(agent, :lending)
# the same as following:
:ok = SecretAgent.fetch_available_account_balance(agent, :lending)
lending_balance = SecretAgent.account_balance(agent, :lending)


active_loans = SecretAgent.active_loans!(agent)
# the same as following:
:ok = SecretAgent.fetch_active_loans(agent)
active_loans = SecretAgent.active_loans(agent)


open_loan_offers = SecretAgent.open_loan_offers!(agent)
# the same as following:
:ok = SecretAgent.fetch_open_loan_offers(agent)
open_loan_offers = SecretAgent.open_loan_offers(agent)
