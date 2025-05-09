/* ---------------------------------------------------------------
   Monthly total of each customer's maximum 30-day rolling average
   balance (negative averages set to 0), excluding the customer’s
   first month of activity (baseline).
---------------------------------------------------------------- */
WITH daily_net AS (                 -- 1. Net amount per customer-day
    SELECT
        "customer_id",
        TO_DATE("txn_date", 'YYYY-MM-DD')                      AS "txn_dt",
        SUM(
            CASE
                WHEN LOWER("txn_type") LIKE 'deposit%' THEN  "txn_amount"
                ELSE                                           -1 * "txn_amount"
            END
        )                                                     AS "net_amount"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date", 'YYYY-MM-DD')
),

running_bal AS (                    -- 2. Running balance
    SELECT
        "customer_id",
        "txn_dt",
        SUM("net_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY      "txn_dt"
            ROWS BETWEEN  UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                   AS "running_balance"
    FROM daily_net
),

rolling_30d AS (                    -- 3. 30-day rolling average balance
    SELECT
        "customer_id",
        "txn_dt",
        GREATEST(
            AVG("running_balance") OVER (
                PARTITION BY "customer_id"
                ORDER BY      "txn_dt"
                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
            ),
            0
        )                                                   AS "avg_30d_balance"
    FROM running_bal
),

monthly_max AS (                    -- 4. Max 30-day average per customer-month
    SELECT
        "customer_id",
        TO_CHAR("txn_dt", 'YYYY-MM')                        AS "yyyy_mm",
        MAX("avg_30d_balance")                              AS "max_avg_30d_bal_in_month"
    FROM rolling_30d
    GROUP BY "customer_id", TO_CHAR("txn_dt", 'YYYY-MM')
),

baseline AS (                       -- 5. Baseline (first) month for each customer
    SELECT
        "customer_id",
        MIN( TO_CHAR( TO_DATE("txn_date", 'YYYY-MM-DD'), 'YYYY-MM') ) 
                                                           AS "baseline_month"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
),

monthly_totals AS (                 -- 6. Sum maxima across customers, excl. baseline
    SELECT
        m."yyyy_mm",
        SUM(m."max_avg_30d_bal_in_month")                  AS "total_max_avg_30d_bal"
    FROM monthly_max m
    JOIN baseline  b  ON m."customer_id" = b."customer_id"
    WHERE m."yyyy_mm" <> b."baseline_month"
    GROUP BY m."yyyy_mm"
)

-- 7. Final ordered result
SELECT
    "yyyy_mm",
    "total_max_avg_30d_bal"
FROM monthly_totals
ORDER BY "yyyy_mm";