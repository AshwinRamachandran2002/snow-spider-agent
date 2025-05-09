/* =======================================================================
   1.  Derive each customer’s net movement per calendar-day
   2.  Build a cumulative running balance per customer
   3.  Calculate a 30-day rolling-average balance
         – only when a full 30-day history exists
         – replace any negative average with 0
   4.  For every month, keep the maximum 30-day average per customer
   5.  Drop each customer’s baseline (first) transaction month
   6.  Sum the remaining monthly maxima across all customers
======================================================================= */
WITH daily_net AS (                           -- step-1
    SELECT
        "customer_id",
        TO_DATE("txn_date")                       AS "txn_date",
        SUM(
            CASE WHEN "txn_type" = 'deposit'
                 THEN  "txn_amount"               -- deposits add
                 ELSE - "txn_amount"              -- all others subtract
            END
        )                                         AS "net_amount"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id", TO_DATE("txn_date")
),
balances AS (                                 -- step-2
    SELECT
        "customer_id",
        "txn_date",
        SUM("net_amount") OVER (
            PARTITION BY "customer_id"
            ORDER BY     "txn_date"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                        AS "running_balance"
    FROM daily_net
),
rolling30 AS (                                -- step-3
    SELECT
        "customer_id",
        "txn_date",
        CASE
            /* ensure a full 30-row window is present   */
            WHEN COUNT(*) OVER (
                     PARTITION BY "customer_id"
                     ORDER BY     "txn_date"
                     ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                 ) = 30
            THEN GREATEST(
                     0,
                     AVG("running_balance") OVER (
                         PARTITION BY "customer_id"
                         ORDER BY     "txn_date"
                         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                     )
                 )
        END                                      AS "rolling_avg_30d"
    FROM balances
),
monthly_max AS (                              -- step-4
    SELECT
        "customer_id",
        TO_CHAR("txn_date",'YYYY-MM')           AS "month",
        MAX("rolling_avg_30d")                  AS "max_avg_30d"
    FROM rolling30
    GROUP BY "customer_id", TO_CHAR("txn_date",'YYYY-MM')
),
baseline_month AS (                           -- customer’s first month
    SELECT
        "customer_id",
        MIN(TO_CHAR(TO_DATE("txn_date"),'YYYY-MM')) AS "baseline_month"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."CUSTOMER_TRANSACTIONS"
    GROUP BY "customer_id"
),
monthly_max_excl_base AS (                    -- step-5
    SELECT mm.*
    FROM monthly_max      mm
    JOIN baseline_month   bm
      ON mm."customer_id" = bm."customer_id"
    WHERE mm."month" <> bm."baseline_month"        -- drop baseline
)
SELECT                                         -- step-6
    "month",
    ROUND(SUM("max_avg_30d"),4)  AS "total_max_avg_30d"
FROM monthly_max_excl_base
GROUP BY "month"
ORDER BY "month" NULLS LAST;