defmodule Krasukha.Helpers.NamingTest do
  use ExUnit.Case, async: true

  import Krasukha.Helpers.Naming


  test "to_name/1" do
    assert to_name("XRP", :lending) == :xrp_lending
    assert process_name("XRP", :lending) == :xrp_lending
  end
end
