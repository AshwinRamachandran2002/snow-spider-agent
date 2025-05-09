SELECT
  "month",
  ROUND(SUM("max_daily_balance"), 4) AS "Total_Max_Daily_Balance"
FROM (
  SELECT
    "customer_id",
    "month",
    MAX("daily_balance") AS "max_daily_balance"
  FROM (
    SELECT
      "customer_id",
      TO_CHAR(TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM') AS "month",
      TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date",
      GREATEST(
        0,
        SUM("txn_amount") OVER (
          PARTITION BY "customer_id"
          ORDER BY TO_DATE("txn_date", 'YYYY-MM-DD')
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
      ) AS "daily_balance"
    FROM
      "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
  ) AS inner_query
  GROUP BY "customer_id", "month"
) AS outer_query
GROUP BY "month"
ORDER BY "month";