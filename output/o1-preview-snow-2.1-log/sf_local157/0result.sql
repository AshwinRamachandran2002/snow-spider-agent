SELECT
  TO_CHAR("Date", 'DD-MM-YYYY') AS "Date",
  "Ticker",
  ROUND((( "TotalQuantity" - "PreviousQuantity" ) / NULLIF("PreviousQuantity", 0)) * 100, 4) AS "Percentage_Change"
FROM (
  SELECT
    "Date",
    "Ticker",
    "TotalQuantity",
    LAG("TotalQuantity") OVER (PARTITION BY "Ticker" ORDER BY "Date") AS "PreviousQuantity"
  FROM (
    SELECT
      TO_DATE("txn_date", 'DD-MM-YYYY') AS "Date",
      "ticker" AS "Ticker",
      SUM("quantity") AS "TotalQuantity"
    FROM
      BANK_SALES_TRADING.BANK_SALES_TRADING.BITCOIN_TRANSACTIONS
    WHERE
      TO_DATE("txn_date", 'DD-MM-YYYY') BETWEEN '2021-08-01' AND '2021-08-10'
    GROUP BY
      TO_DATE("txn_date", 'DD-MM-YYYY'),
      "ticker"
  ) 
)
WHERE
  "PreviousQuantity" IS NOT NULL
ORDER BY
  "Date", "Ticker";