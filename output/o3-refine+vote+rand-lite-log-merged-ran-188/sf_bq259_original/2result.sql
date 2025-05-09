/*------------------------------------------------------------
 Cohort analysis : share of users that buy again in the
 1st, 2nd, 3rd and 4th month (month 0‑3) after their very
 first purchase.  Data limited to orders created up to
 31‑Dec‑2022 (inclusive).
------------------------------------------------------------*/
WITH orders_2022 AS (          -- all orders up to end‑2022
    SELECT
        "user_id",
        TO_TIMESTAMP_NTZ("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE TO_TIMESTAMP_NTZ("created_at" / 1000000) < '2023-01-01'
      AND "user_id" IS NOT NULL
),
first_order_per_user AS (      -- first purchase per user
    SELECT
        "user_id",
        MIN(order_ts) AS first_order_ts
    FROM orders_2022
    GROUP BY "user_id"
),
cohort_lookup AS (             -- cohort month for every user
    SELECT
        "user_id",
        DATE_TRUNC('month', first_order_ts) AS cohort_month,
        first_order_ts
    FROM first_order_per_user
),
orders_with_index AS (         -- month index (0‑3) of every order
    SELECT
        o."user_id",
        c.cohort_month,
        DATEDIFF(
            'month',
            DATE_TRUNC('month', c.first_order_ts),
            DATE_TRUNC('month', o.order_ts)
        ) AS months_since
    FROM orders_2022 o
    JOIN cohort_lookup c USING ("user_id")
    WHERE DATEDIFF(
              'month',
              DATE_TRUNC('month', c.first_order_ts),
              DATE_TRUNC('month', o.order_ts)
          ) BETWEEN 0 AND 3
),
unique_user_month AS (         -- at most one row per user & month
    SELECT DISTINCT
        cohort_month,
        months_since,
        "user_id"
    FROM orders_with_index
),
cohort_size AS (               -- users in each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_users
    FROM cohort_lookup
    GROUP BY cohort_month
),
cohort_user_counts AS (        -- users who bought in each month 0‑3
    SELECT
        cohort_month,
        months_since,
        COUNT(DISTINCT "user_id") AS users_purchased
    FROM unique_user_month
    GROUP BY cohort_month, months_since
)
/*--------------  final result  -----------------------------*/
SELECT
    cs.cohort_month,
    ROUND(100 * COALESCE(MAX(CASE WHEN cuc.months_since = 0 THEN cuc.users_purchased END), 0)
              / cs.cohort_users, 4) AS pct_users_month_1,   -- month of first purchase
    ROUND(100 * COALESCE(MAX(CASE WHEN cuc.months_since = 1 THEN cuc.users_purchased END), 0)
              / cs.cohort_users, 4) AS pct_users_month_2,
    ROUND(100 * COALESCE(MAX(CASE WHEN cuc.months_since = 2 THEN cuc.users_purchased END), 0)
              / cs.cohort_users, 4) AS pct_users_month_3,
    ROUND(100 * COALESCE(MAX(CASE WHEN cuc.months_since = 3 THEN cuc.users_purchased END), 0)
              / cs.cohort_users, 4) AS pct_users_month_4
FROM cohort_size cs
LEFT JOIN cohort_user_counts cuc
       ON cs.cohort_month = cuc.cohort_month
GROUP BY cs.cohort_month, cs.cohort_users
ORDER BY cs.cohort_month;