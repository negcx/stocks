defmodule StocksTest do
  use ExUnit.Case
  doctest Stocks

  test "greets the world" do
    assert Stocks.hello() == :world
  end
end
