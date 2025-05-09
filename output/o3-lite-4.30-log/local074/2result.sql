WITH
    -- Determine first and last transaction months
    bounds AS (
        SELECT
            date(MIN("txn_date"), 'start of month') AS first_month,
            date(MAX("txn_date"), 'start of month') AS last_month
        FROM "customer_transactions"
    ),

    -- Generate every calendar month between the bounds (inclusive)
    months(mnth) AS (
        SELECT first_month FROM bounds
        UNION ALL
        SELECT date(mnth, '+1 month')
        FROM months, bounds
        WHERE mnth < date(last_month, '+1 month')
    ),

    -- Calendar month key and last day of each month
    month_bounds AS (
        SELECT
            strftime('%Y-%m', mnth)          AS month_key,
            date(mnth, '+1 month', '-1 day') AS month_end
        FROM months
    ),

    -- All customers appearing in the data
    customers AS (
        SELECT DISTINCT "customer_id"
        FROM "customer_transactions"
    ),

    -- Net monthly change (+deposit, −withdrawal)
    monthly_change AS (
        SELECT
            "customer_id",
            strftime('%Y-%m', "txn_date")    AS month_key,
            SUM(CASE
                    WHEN "txn_type" = 'deposit'    THEN  "txn_amount"
                    WHEN "txn_type" = 'withdrawal' THEN - "txn_amount"
                    ELSE 0
                END)                        AS change_amt
        FROM "customer_transactions"
        GROUP BY "customer_id", month_key
    ),

    -- Full customer‑month grid
    grid AS (
        SELECT
            c."customer_id",
            mb.month_key,
            mb.month_end
        FROM customers c
        CROSS JOIN month_bounds mb
    ),

    -- Attach changes, default missing months to zero
    merged AS (
        SELECT
            g."customer_id",
            g.month_end,
            COALESCE(mc.change_amt, 0) AS monthly_change
        FROM grid g
        LEFT JOIN monthly_change mc
               ON mc."customer_id" = g."customer_id"
              AND mc.month_key     = g.month_key
    )

-- Final result with cumulative closing balance
SELECT
    "customer_id",
    month_end,
    printf('%.4f', monthly_change)                                   AS monthly_change,
    printf('%.4f',
           SUM(monthly_change) OVER (
               PARTITION BY "customer_id"
               ORDER BY month_end
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           )
    )                                                                AS closing_balance
FROM merged
ORDER BY "customer_id", month_end;