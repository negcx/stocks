# Stocks

A very simple stock market CLI.

## Compilation

`MIX_ENV=prod mix release`

You should have a binary in `_build/prod/rel/bakeware/stocks` which you can link into your PATH.

## Usage

Stocks is expecting there to be a `stocks.json` file in your `$HOME` directory. This file needs an API Key from https://www.alphavantage.co/support/#api-key and a list of your stock holdings.

```
{
  "api_key": "YourKeyHere",
  "stocks": [
    {
      "symbol": "DOCN",
      "quantity": 1000,
      "buy_date": "2021-03-24",
      "buy_price": 44.35
    },
    {
      "symbol": "AAPL",
      "quantity": 1000,
      "buy_date": "2021-03-24",
      "buy_price": 100.5
    }
}
```
