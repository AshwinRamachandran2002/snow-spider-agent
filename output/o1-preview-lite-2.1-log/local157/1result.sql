WITH raw_dates AS (
  SELECT
    date(substr("txn_date", 7, 4) || '-' || substr("txn_date", 4, 2) || '-' || substr("txn_date", 1, 2)) AS "Date",
    "ticker",
    "quantity"
  FROM "bitcoin_transactions"
),
daily_volumes AS (
  SELECT
    "Date",
    "ticker",
    SUM("quantity") AS "total_quantity"
  FROM raw_dates
  WHERE "Date" BETWEEN '2021-07-31' AND '2021-08-10'
  GROUP BY "Date", "ticker"
)
SELECT
  dv1."Date",
  dv1."Ticker",
  ROUND(((dv1."total_quantity" - dv2."total_quantity") / dv2."total_quantity") * 100, 4) AS "Percentage_Change"
FROM
  daily_volumes dv1
LEFT JOIN
  daily_volumes dv2 ON
    dv1."Ticker" = dv2."Ticker" AND
    dv2."Date" = date(dv1."Date", '-1 day')
WHERE
  dv1."Date" BETWEEN '2021-08-01' AND '2021-08-10'
ORDER BY
  dv1."Date",
  dv1."Ticker";