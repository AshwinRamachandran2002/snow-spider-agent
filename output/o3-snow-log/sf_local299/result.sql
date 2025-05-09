/* ----------------------------------------------------------
   Monthly totals of summed maximum 30-day average balances
   (baseline month per customer is excluded)

   – Deposits  : add to balance
   – All other : subtract from balance
   – 30-day window is calculated even if <30 prior rows exist;
     any negative rolling average is clipped to 0.
-----------------------------------------------------------*/

WITH daily AS (                         -- 1. net movement per customer/day
    SELECT
        "customer_id",
        "txn_date",
        SUM(
            CASE
                WHEN LOWER("txn_type") LIKE '%deposit%' THEN  "txn_amount"
                ELSE -1 * "txn_amount"
            END
        ) AS "net_amt"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", "txn_date"
), balances AS (                        -- 2. running balance
    SELECT
        "customer_id",
        "txn_date",
        SUM("net_amt") OVER (
            PARTITION BY "customer_id"
            ORDER BY     "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "running_bal"
    FROM daily
), cust_avg AS (                        -- 3. 30-day rolling average, negatives ⇒ 0
    SELECT
        "customer_id",
        LEFT("txn_date", 7) AS "year_month",
        GREATEST(
            AVG("running_bal") OVER (
                PARTITION BY "customer_id"
                ORDER BY     "txn_date"
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ),
            0
        ) AS "avg_bal_30d"
    FROM balances
), cust_month_max AS (                  -- 4. max 30-day avg balance per customer/month
    SELECT
        "customer_id",
        "year_month",
        MAX("avg_bal_30d") AS "max_avg_bal_30d"
    FROM cust_avg
    GROUP BY "customer_id", "year_month"
), baseline AS (                        -- 5. first transaction month per customer
    SELECT
        "customer_id",
        MIN(LEFT("txn_date", 7)) AS "baseline_month"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id"
)
-- 6. final monthly totals (exclude each customer's baseline month)
SELECT
    cm."year_month",
    SUM(cm."max_avg_bal_30d") AS "total_max_30d_balance"
FROM cust_month_max cm
JOIN baseline b
  ON cm."customer_id" = b."customer_id"
WHERE cm."year_month" <> b."baseline_month"
GROUP BY cm."year_month"
ORDER BY cm."year_month";