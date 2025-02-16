-- Task: For each customer, calculate their daily balances for every day between their earliest and latest transaction dates, including days without transactions by carrying forward the previous day's balance. Treat any negative daily balances as zero. Return the first 100 rows.
WITH RECURSIVE customer_date_series AS (
    SELECT "customer_id", 
           MIN("txn_date")::DATE AS "date_series",
           MAX("txn_date")::DATE AS "last_date"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
    UNION ALL
    SELECT "customer_id", 
           DATEADD(DAY, 1, "date_series") AS "date_series",
           "last_date"
    FROM customer_date_series
    WHERE DATEADD(DAY, 1, "date_series") <= "last_date"
),
customer_txn AS (
    SELECT *,
           CASE WHEN "txn_type" = 'deposit' THEN "txn_amount"
                ELSE -1 * "txn_amount" END AS "txn_group"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
customer_balance AS (
    SELECT s."customer_id", 
           s."date_series", 
           COALESCE(b."txn_group", 0) AS "txn_group",
           SUM(COALESCE(b."txn_group", 0)) OVER (PARTITION BY s."customer_id" ORDER BY s."date_series") AS "balance"
    FROM customer_date_series s
    LEFT JOIN customer_txn b 
        ON s."customer_id" = b."customer_id" 
        AND s."date_series" = b."txn_date"
    ORDER BY s."customer_id", s."date_series"
),
customer_data AS (
    SELECT "customer_id", 
           "date_series",
           CASE WHEN "balance" < 0 THEN 0
                ELSE "balance" END AS "data_storage"
    FROM customer_balance
)
SELECT "customer_id", "date_series", "data_storage"
FROM customer_data
LIMIT 100;