-- Task: For each of the Magnificent 7 tech companies, provide the start-of-year date and post-market close price, as well as the latest date and post-market close price between January 1 and June 30, 2024.

WITH price_data AS (
  SELECT
    ticker,
    date,
    value
  FROM FINANCE__ECONOMICS.CYBERSYN.STOCK_PRICE_TIMESERIES
  WHERE
    ticker IN ('AAPL', 'MSFT', 'AMZN', 'GOOGL', 'META', 'TSLA', 'NVDA')
    AND date BETWEEN DATE '2024-01-01' AND DATE '2024-06-30'
    AND variable_name = 'Post-Market Close'
),
start_prices AS (
  SELECT
    pd.ticker,
    pd.date AS start_of_year_date,
    pd.value AS start_of_year_price
  FROM price_data pd
  INNER JOIN (
    SELECT
      ticker,
      MIN(date) AS min_date
    FROM price_data
    GROUP BY ticker
  ) md ON pd.ticker = md.ticker AND pd.date = md.min_date
),
latest_prices AS (
  SELECT
    pd.ticker,
    pd.date AS latest_date,
    pd.value AS latest_price
  FROM price_data pd
  INNER JOIN (
    SELECT
      ticker,
      MAX(date) AS max_date
    FROM price_data
    GROUP BY ticker
  ) md ON pd.ticker = md.ticker AND pd.date = md.max_date
)
SELECT
  sp.ticker,
  sp.start_of_year_date,
  sp.start_of_year_price,
  lp.latest_date,
  lp.latest_price
FROM
  start_prices sp
JOIN
  latest_prices lp ON sp.ticker = lp.ticker
ORDER BY
  sp.ticker;