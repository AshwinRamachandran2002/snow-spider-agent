WITH date_range AS (
   SELECT 
       MIN(TO_DATE("txn_date", 'YYYY-MM-DD')) AS min_date,
       MAX(TO_DATE("txn_date", 'YYYY-MM-DD')) AS max_date
   FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
calendar AS (
    SELECT min_date AS "txn_date" FROM date_range
    UNION ALL
    SELECT DATEADD('day', 1, "txn_date") AS "txn_date"
    FROM calendar
    WHERE "txn_date" < (SELECT max_date FROM date_range)
),
customers AS (
   SELECT DISTINCT "customer_id"
   FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
),
customer_dates AS (
   SELECT c."customer_id", cal."txn_date"
   FROM customers c
   CROSS JOIN calendar cal
),
txn_amounts AS (
   SELECT
       "customer_id",
       TO_DATE("txn_date", 'YYYY-MM-DD') AS "txn_date",
       SUM(
           CASE
               WHEN "txn_type" = 'deposit' THEN "txn_amount"
               WHEN "txn_type" = 'withdrawal' THEN -"txn_amount"
               ELSE 0
           END
       ) AS "daily_net_amount"
   FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
   GROUP BY "customer_id", TO_DATE("txn_date", 'YYYY-MM-DD')
),
customer_balances AS (
   SELECT
       cd."customer_id",
       cd."txn_date",
       COALESCE(ta."daily_net_amount", 0) AS "net_amount"
   FROM customer_dates cd
   LEFT JOIN txn_amounts ta ON cd."customer_id" = ta."customer_id"
                             AND cd."txn_date" = ta."txn_date"
),
customer_balance_cumulative AS (
   SELECT
       cb."customer_id",
       cb."txn_date",
       SUM(cb."net_amount") OVER (
           PARTITION BY cb."customer_id"
           ORDER BY cb."txn_date"
       ) AS "balance"
   FROM customer_balances cb
),
customer_avg_balance AS (
   SELECT
       cb."customer_id",
       cb."txn_date",
       (
           SELECT AVG(cb2."balance")
           FROM customer_balance_cumulative cb2
           WHERE cb2."customer_id" = cb."customer_id"
             AND cb2."txn_date" >= DATEADD('day', -29, cb."txn_date")
             AND cb2."txn_date" <= cb."txn_date"
       ) AS "avg_balance_past_30_days"
   FROM customer_balance_cumulative cb
),
customer_avg_balance_monthly AS (
    SELECT
        "customer_id",
        "txn_date",
        DATE_TRUNC('month', "txn_date") AS "month",
        "avg_balance_past_30_days"
    FROM customer_avg_balance
),
first_month AS (
    SELECT MIN("month") AS min_month
    FROM customer_avg_balance_monthly
),
customer_max_monthly_avg_balance AS (
    SELECT
        "customer_id",
        "month",
        MAX("avg_balance_past_30_days") AS "max_avg_balance"
    FROM customer_avg_balance_monthly
    WHERE "month" > (SELECT min_month FROM first_month)
    GROUP BY "customer_id", "month"
)
SELECT
    TO_CHAR("month", 'YYYY-MM') AS "Month",
    ROUND(SUM("max_avg_balance"), 4) AS "Total_Max_Daily_Average"
FROM customer_max_monthly_avg_balance
GROUP BY "month"
ORDER BY "month";