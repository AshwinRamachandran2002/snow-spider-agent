WITH first_orders AS (
    /* 1. First non‑cancelled purchase month for every user */
    SELECT
        "user_id",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_LTZ("created_at"/1e6)
        )                              AS first_order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
),

/* 2. Users whose very first purchase happened in January‑2020 */
cohort AS (
    SELECT DISTINCT "user_id"
    FROM first_orders
    WHERE first_order_month = '2020-01-01'::DATE      -- cohort month
),

/* 3. All 2020 orders (non‑cancelled) placed by those cohort users */
orders_2020 AS (
    SELECT
        o."user_id",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_LTZ(o."created_at"/1e6)
        )                              AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN cohort c
      ON c."user_id" = o."user_id"
    WHERE o."status" <> 'Cancelled'
      AND DATE_TRUNC('year', TO_TIMESTAMP_LTZ(o."created_at"/1e6)) = '2020-01-01'::DATE
      AND DATE_TRUNC('month',
                     TO_TIMESTAMP_LTZ(o."created_at"/1e6)
          ) > '2020-01-01'::DATE        -- exclude the cohort month itself
),

/* 4. Month list: Feb‑2020 through Dec‑2020 */
month_list AS (
    SELECT DATEADD('month', seq4(), '2020-02-01'::DATE) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 11))               -- 11 months, Feb‑Dec
),

/* 5. Returning user count per month */
monthly_returns AS (
    SELECT
        ml.month_start,
        COUNT(DISTINCT o."user_id") AS returning_users
    FROM month_list ml
    LEFT JOIN orders_2020 o
           ON o.order_month = ml.month_start
    GROUP BY ml.month_start
),

cohort_size AS (
    SELECT COUNT(*) AS cohort_cnt FROM cohort
)

/* 6. Proportion of cohort users who returned each month */
SELECT
    TO_CHAR(month_start, 'YYYY-MM')                           AS "month",
    ROUND(returning_users::FLOAT / cohort_cnt, 4)             AS "returning_user_proportion"
FROM monthly_returns, cohort_size
ORDER BY month_start;