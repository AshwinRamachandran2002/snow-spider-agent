-- Task: Calculate daily cumulative balances for each customer by summing their transactions, where deposits are positive and withdrawals are negative. Then, starting from the 31st day (to ensure a full 30-day period), compute for each customer and each day the average balance over the past 30 days (including the current day). If this average is negative, set it to zero. For each month (based on the month and year of the date), find the maximum of these daily 30-day average balances for each customer within that month. Sum these maximum values across all customers to obtain the total allocation per month. Exclude the first month from the output, using it as a baseline for previous balances.

WITH RECURSIVE customer_date_series AS (
    -- Anchor part: ensure 'date_series' is of DATE type
    SELECT "customer_id", 
           MIN("txn_date")::DATE AS "date_series",  -- Ensure this is a DATE type
           MAX("txn_date")::DATE AS "last_date"     -- Ensure this is a DATE type
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"

    UNION ALL

    -- Recursive part: ensure 'date_series' is of DATE type
    SELECT "customer_id", 
           DATEADD(DAY, 1, "date_series") AS "date_series",  -- Ensure this adds 1 day to a DATE
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
           CASE WHEN "txn_row" < 30 THEN NULL
                WHEN "avg_last_30" < 0 THEN 0
                ELSE "avg_last_30" END AS "data_storage"
    FROM (
        SELECT *,
               AVG("balance") OVER (PARTITION BY "customer_id" ORDER BY "date_series" 
                                    ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS "avg_last_30",
               ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY "date_series") AS "txn_row"
        FROM customer_balance
    ) AS tmp
),
monthly_data AS (
    SELECT "customer_id",
           TO_CHAR("date_series", 'YYYY-MM') AS "month",  -- Ensure 'date_series' is a valid DATE or TIMESTAMP
           MAX("data_storage") AS "data_allocation",
           ROW_NUMBER() OVER (PARTITION BY "customer_id" ORDER BY TO_CHAR("date_series", 'YYYY-MM')) AS "month_row"
    FROM customer_data
    GROUP BY "customer_id", TO_CHAR("date_series", 'YYYY-MM')
)
SELECT "month", 
       SUM("data_allocation") AS "total_allocation"
FROM monthly_data
WHERE "month_row" > 1
GROUP BY "month";