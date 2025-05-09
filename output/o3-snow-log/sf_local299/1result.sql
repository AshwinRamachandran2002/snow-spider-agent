/* -----------------------------------------------------------
   Monthly totals of each customer’s maximum 30-day rolling
   average balance (post-baseline month only)
   ----------------------------------------------------------- */
WITH daily AS (   -- 1) net amount per customer/day
    SELECT
        "customer_id",
        TO_DATE("txn_date")                                  AS "txn_date",
        SUM(
            CASE WHEN "txn_type" = 'deposit'
                 THEN  "txn_amount"          -- deposits add
                 ELSE -1 * "txn_amount"      -- all others subtract
            END
        )                                                    AS "net_amount"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
),

running AS (      -- 2) running balance per customer
    SELECT
        "customer_id",
        "txn_date",
        SUM("net_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY      "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                  AS "running_balance"
    FROM daily
),

rolling AS (      -- 3) 30-day rolling average balance
    SELECT
        "customer_id",
        "txn_date",
        AVG("running_balance") OVER (
            PARTITION BY "customer_id"
            ORDER BY      "txn_date"
            RANGE BETWEEN INTERVAL '29 DAY' PRECEDING AND CURRENT ROW
        )                                                  AS "avg_30day_balance"
    FROM running
    /* keep rows only after 30 calendar days of history exist */
    QUALIFY DATEDIFF(
                day,
                MIN("txn_date") OVER (PARTITION BY "customer_id"),
                "txn_date"
            ) >= 29
),

positive AS (     -- 4) force negative rolling averages to zero
    SELECT
        "customer_id",
        "txn_date",
        GREATEST("avg_30day_balance", 0) AS "avg_30day_balance_pos"
    FROM rolling
),

monthly_max AS (  -- 5) each customer’s maximum 30-day avg per month
    SELECT
        "customer_id",
        DATE_TRUNC('month', "txn_date")  AS "month_start",
        MAX("avg_30day_balance_pos")     AS "max_30day_avg_in_month"
    FROM positive
    GROUP BY "customer_id", DATE_TRUNC('month', "txn_date")
),

baseline AS (     -- 6) identify every customer’s first (baseline) month
    SELECT
        "customer_id",
        DATE_TRUNC('month', MIN(TO_DATE("txn_date"))) AS "baseline_month"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
)

/* 7) final result – exclude baseline month and sum across customers */
SELECT
    m."month_start",
    SUM(m."max_30day_avg_in_month") AS "sum_of_customer_monthly_max"
FROM monthly_max  m
JOIN baseline     b
  ON m."customer_id" = b."customer_id"
WHERE m."month_start" <> b."baseline_month"   -- drop baseline month
GROUP BY m."month_start"
ORDER BY m."month_start";