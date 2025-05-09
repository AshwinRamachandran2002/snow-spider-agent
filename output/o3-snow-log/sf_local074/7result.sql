WITH date_bounds AS (   -- find first & last transaction dates
    SELECT
        MIN(TO_DATE("txn_date")) AS min_date,
        MAX(TO_DATE("txn_date")) AS max_date
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

months AS (             -- generate every month between those dates
    SELECT
        DATE_TRUNC('MONTH',
                   DATEADD('MONTH', seq4(), min_date)) AS month_start
    FROM date_bounds,
         TABLE(GENERATOR(ROWCOUNT => 1200))            -- constant upper-bound
    WHERE seq4() <= DATEDIFF('MONTH', min_date, max_date)
),

customers AS (          -- distinct customers
    SELECT DISTINCT "customer_id"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
),

customer_months AS (    -- cartesian product: every customer × every month
    SELECT
        c."customer_id",
        m.month_start
    FROM customers c
    CROSS JOIN months m
),

monthly_activity AS (   -- net deposits (+)/withdrawals (–) per month
    SELECT
        "customer_id",
        DATE_TRUNC('MONTH', TO_DATE("txn_date"))        AS month_start,
        SUM(
            CASE 
                WHEN LOWER("txn_type") = 'deposit'    THEN  "txn_amount"
                WHEN LOWER("txn_type") = 'withdrawal' THEN - "txn_amount"
                ELSE 0
            END
        )                                              AS net_activity
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CUSTOMER_TRANSACTIONS
    GROUP BY "customer_id", month_start
),

full_data AS (          -- include months with zero activity
    SELECT
        cm."customer_id",
        cm.month_start,
        COALESCE(ma.net_activity, 0) AS net_activity
    FROM customer_months cm
    LEFT JOIN monthly_activity ma
           ON  cm."customer_id" = ma."customer_id"
          AND cm.month_start    = ma.month_start
),

running_balances AS (   -- cumulative closing balance
    SELECT
        "customer_id",
        month_start,
        net_activity,
        SUM(net_activity) OVER (PARTITION BY "customer_id"
                                ORDER BY month_start
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
    FROM full_data
)

SELECT
    "customer_id",
    TO_CHAR(month_start, 'YYYY-MM')                                                   AS month_year,
    COALESCE(
        closing_balance 
        - LAG(closing_balance) OVER (PARTITION BY "customer_id" ORDER BY month_start),
        closing_balance
    )                                                                                 AS monthly_change,
    closing_balance
FROM running_balances
ORDER BY "customer_id", month_start;