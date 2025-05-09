/*--------------------------------------------------------------------
Monthly closing balances, monthly changes and running balances
for every customer – months with no activity are still shown
--------------------------------------------------------------------*/
WITH date_bounds AS (   /* overall limits and month span */
    SELECT
        MIN(TO_DATE("txn_date",'YYYY-MM-DD'))                                    AS min_date,
        MAX(TO_DATE("txn_date",'YYYY-MM-DD'))                                    AS max_date,
        DATEDIFF(
            MONTH ,
            DATE_TRUNC('MONTH', MIN(TO_DATE("txn_date",'YYYY-MM-DD'))),
            DATE_TRUNC('MONTH', MAX(TO_DATE("txn_date",'YYYY-MM-DD')))
        )                                                                        AS diff_months
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

months AS (             /* full sequence of months (constant ROWCOUNT) */
    SELECT
        DATEADD(
            MONTH,
            SEQ4() ,                                   -- 0,1,2,…
            DATE_TRUNC('MONTH', min_date)
        )                                              AS month_start
    FROM date_bounds,
         TABLE(GENERATOR(ROWCOUNT => 12000))           -- plenty of rows
    WHERE SEQ4() <= diff_months                        -- keep needed span
),

customers AS (          /* every customer appearing in data */
    SELECT DISTINCT "customer_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

customer_months AS (    /* cartesian: each customer × each month */
    SELECT
        c."customer_id",
        m.month_start
    FROM customers c
    CROSS JOIN months m
),

monthly_changes AS (    /* net change per customer per month */
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', TO_DATE("txn_date",'YYYY-MM-DD')) AS month_start,
        SUM(
            CASE
                WHEN LOWER("txn_type") = 'deposit'                  THEN  "txn_amount"
                WHEN LOWER("txn_type") IN ('withdraw','withdrawal') THEN - "txn_amount"
                ELSE 0
            END
        ) AS monthly_change
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY
        "customer_id",
        DATE_TRUNC('MONTH', TO_DATE("txn_date",'YYYY-MM-DD'))
),

full_grid AS (          /* attach actual changes to full grid */
    SELECT
        cm."customer_id",
        cm.month_start,
        COALESCE(mc.monthly_change, 0) AS monthly_change
    FROM customer_months cm
    LEFT JOIN monthly_changes mc
      ON cm."customer_id" = mc."customer_id"
     AND cm.month_start   = mc.month_start
)

SELECT
    "customer_id",
    TO_CHAR(month_start,'YYYY-MM')                       AS "month",
    monthly_change                                       AS "monthly_change",
    SUM(monthly_change) OVER (
        PARTITION BY "customer_id"
        ORDER BY month_start
    )                                                    AS "cumulative_balance"
FROM full_grid
ORDER BY
    "customer_id",
    month_start NULLS LAST;