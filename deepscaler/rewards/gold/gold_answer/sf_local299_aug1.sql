-- Task: For each customer, generate a list of dates from their earliest transaction date to their latest transaction date. Show the first 100 rows.
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
)
SELECT * FROM customer_date_series
LIMIT 100;