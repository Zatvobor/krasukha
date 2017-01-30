# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

    config :logger,
      utc_log: true,
      level: if(Mix.env == :dev, do: :info, else: :warn),
      handle_otp_reports: true,
      handle_sasl_reports: true
