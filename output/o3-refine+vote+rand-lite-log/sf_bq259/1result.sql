WITH orders_filtered AS (   -- all purchases up to the end of 2022
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at" / 1000000))      AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) < '2023-01-01'
      AND "user_id" IS NOT NULL
),
user_first_order AS (       -- first‑purchase month (cohort) for every user
    SELECT
        "user_id",
        MIN(order_date)                          AS first_order_date,
        DATE_TRUNC('month', MIN(order_date))     AS cohort_month
    FROM orders_filtered
    GROUP BY "user_id"
),
orders_with_diff AS (       -- month offset (0‑3) of every later purchase
    SELECT
        o."user_id",
        f.cohort_month,
        DATEDIFF(
            'month',
            f.cohort_month,
            DATE_TRUNC('month', o.order_date)
        ) AS month_number                       -- 0 = first month, 1 = second, etc.
    FROM orders_filtered o
    JOIN user_first_order  f  ON o."user_id" = f."user_id"
    WHERE DATEDIFF(
            'month',
            f.cohort_month,
            DATE_TRUNC('month', o.order_date)
          ) BETWEEN 0 AND 3                      -- keep only the first 4 months
),
cohort_sizes AS (           -- size of every cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_size
    FROM user_first_order
    GROUP BY cohort_month
),
retention_raw AS (          -- distinct users who purchased in each offset month
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT "user_id") AS users_in_period
    FROM orders_with_diff
    GROUP BY cohort_month, month_number
),
retention_pct AS (          -- convert to percentages
    SELECT
        r.cohort_month,
        r.month_number,
        (r.users_in_period * 100.0) / c.cohort_size AS pct_users
    FROM retention_raw  r
    JOIN cohort_sizes  c  ON r.cohort_month = c.cohort_month
)
SELECT
    cohort_month,
    ROUND(MAX(CASE WHEN month_number = 0 THEN pct_users END), 4) AS first_month_pct,
    ROUND(MAX(CASE WHEN month_number = 1 THEN pct_users END), 4) AS second_month_pct,
    ROUND(MAX(CASE WHEN month_number = 2 THEN pct_users END), 4) AS third_month_pct,
    ROUND(MAX(CASE WHEN month_number = 3 THEN pct_users END), 4) AS fourth_month_pct
FROM retention_pct
GROUP BY cohort_month
ORDER BY cohort_month;