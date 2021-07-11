defmodule Stocks do
  alias TableRex.Table
  import Number.Currency
  import Number.Percentage

  use Bakeware.Script

  @impl Bakeware.Script
  def main(_args) do
    run()
    0
  end

  def load_settings do
    File.read!(System.get_env("HOME") |> Path.join("stocks.json"))
    |> Jason.decode!()
  end

  def currency_cell(v) do
    formatted = number_to_currency(v, precision: 0)

    %TableRex.Cell{
      align: nil,
      color: nil,
      raw_value: formatted,
      rendered_value: formatted,
      wrapped_lines: [formatted]
    }
  end

  def color_from_value(v) when v > 0.0, do: :green
  def color_from_value(v) when v < 0.0, do: :red
  def color_from_value(v) when v == 0.0, do: nil

  def colored_currency_cell(v) do
    formatted = number_to_currency(v, precision: 0)

    %TableRex.Cell{
      align: nil,
      color: color_from_value(v),
      raw_value: formatted,
      rendered_value: formatted,
      wrapped_lines: [formatted]
    }
  end

  def colored_percentage_cell(v) do
    formatted = number_to_percentage(v * 100, precision: 2)

    %TableRex.Cell{
      align: nil,
      color: color_from_value(v),
      raw_value: formatted,
      rendered_value: formatted,
      wrapped_lines: [formatted]
    }
  end

  def current_prices(symbols, api_key) do
    symbols
    |> Enum.map(fn symbol ->
      Task.async(fn ->
        HTTPoison.get!("https://www.alphavantage.co/query", [],
          params: [
            function: "GLOBAL_QUOTE",
            symbol: symbol,
            apikey: api_key
          ]
        )
      end)
    end)
    |> Task.await_many()
    |> Enum.map(&Map.get(&1, :body))
    |> Enum.map(&Jason.decode!/1)
    |> Enum.reduce(%{}, fn q, acc ->
      Map.put(acc, q["Global Quote"]["01. symbol"], %{
        price: String.to_float(q["Global Quote"]["05. price"]),
        previous_price: String.to_float(q["Global Quote"]["08. previous close"])
      })
    end)
  end

  def run do
    settings = load_settings()

    symbols =
      MapSet.new(
        settings["stocks"]
        |> Enum.map(&Map.get(&1, "symbol"))
      )

    prices = current_prices(symbols, settings["api_key"])

    data =
      settings["stocks"]
      |> Enum.map(fn stock ->
        stock
        |> Map.put("cost_basis", stock["quantity"] * stock["buy_price"])
        |> Map.put("value", stock["quantity"] * Map.get(prices, stock["symbol"]).price)
        |> Map.put(
          "previous_value",
          stock["quantity"] * Map.get(prices, stock["symbol"]).previous_price
        )
      end)
      |> Enum.group_by(
        &Map.get(&1, "symbol"),
        &Map.take(&1, ["cost_basis", "previous_value", "value"])
      )
      |> Enum.reduce(%{}, fn {symbol, prices}, acc ->
        acc
        |> Map.put(
          symbol,
          Enum.reduce(
            prices,
            %{
              cost_basis: 0.0,
              previous_value: 0.0,
              value: 0.0
            },
            fn price, price_acc ->
              price_acc
              |> Map.update!(:cost_basis, fn existing ->
                existing + price["cost_basis"]
              end)
              |> Map.update!(:previous_value, fn existing ->
                existing + price["previous_value"]
              end)
              |> Map.update!(:value, fn existing ->
                existing + price["value"]
              end)
            end
          )
        )
      end)

    total =
      data
      |> Enum.reduce(%{cost_basis: 0.0, value: 0.0, previous_value: 0.0}, fn {_, value}, acc ->
        acc
        |> Map.update!(:cost_basis, fn v -> v + value.cost_basis end)
        |> Map.update!(:value, fn v -> v + value.value end)
        |> Map.update!(:previous_value, fn v -> v + value.previous_value end)
      end)

    rows =
      data
      |> Enum.map(fn {symbol, values} ->
        [
          TableRex.Cell.to_cell(symbol),
          currency_cell(values.cost_basis),
          currency_cell(values.value),
          colored_currency_cell(values.value - values.cost_basis),
          colored_percentage_cell((values.value - values.cost_basis) / values.cost_basis),
          colored_currency_cell(values.value - values.previous_value),
          colored_percentage_cell((values.value - values.previous_value) / values.previous_value)
        ]
      end)

    []
    |> Table.new(["Symbol", "Cost Basis", "Value", "Change", "%", "Day Change", "Day %"])
    |> Map.put(:rows, rows)
    |> Table.sort(0, :asc)
    |> Map.update!(:rows, fn existing ->
      [
        [
          TableRex.Cell.to_cell("Total"),
          currency_cell(total.cost_basis),
          currency_cell(total.value),
          colored_currency_cell(total.value - total.cost_basis),
          colored_percentage_cell((total.value - total.cost_basis) / total.cost_basis),
          colored_currency_cell(total.value - total.previous_value),
          colored_percentage_cell((total.value - total.previous_value) / total.previous_value)
        ],
        [
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell(""),
          TableRex.Cell.to_cell("")
        ]
      ] ++
        existing
    end)
    |> Table.put_column_meta(1..6, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
