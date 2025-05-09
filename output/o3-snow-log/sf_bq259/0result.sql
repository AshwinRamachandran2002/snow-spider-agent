/* Cohort analysis – percentage of users that make a purchase
   in the 1st, 2nd, 3rd and 4th calendar months after their
   very first purchase (cohort defined by first-purchase month)
   – data limited to orders created ≤ 31-Dec-2022                */

WITH cleaned_orders AS (   -- keep only real (non-cancelled) 2022-and-before orders
    SELECT
        "user_id",
        TO_TIMESTAMP( "created_at" / 1000000 )           AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
      AND TO_TIMESTAMP( "created_at" / 1000000 ) < '2023-01-01'
      AND "user_id" IS NOT NULL
),

first_purchase AS (        -- first purchase date for every user
    SELECT
        "user_id",
        MIN(order_ts) AS first_order_ts
    FROM cleaned_orders
    GROUP BY "user_id"
),

orders_with_offsets AS (   -- how many months after first purchase the order happened
    SELECT
        o."user_id",
        DATE_TRUNC('month', f.first_order_ts)                                         AS cohort_month,
        DATEDIFF(
            month,
            DATE_TRUNC('month', f.first_order_ts),
            DATE_TRUNC('month', o.order_ts)
        )                                                                            AS month_offset
    FROM cleaned_orders            o
    JOIN first_purchase            f  ON o."user_id" = f."user_id"
    WHERE DATEDIFF(
              month,
              DATE_TRUNC('month', f.first_order_ts),
              DATE_TRUNC('month', o.order_ts)
          ) BETWEEN 0 AND 3                      -- only the first four months
),

cohort_sizes AS (          -- number of users in every cohort
    SELECT
        DATE_TRUNC('month', first_order_ts) AS cohort_month,
        COUNT(DISTINCT "user_id")           AS cohort_users
    FROM first_purchase
    WHERE first_order_ts < '2023-01-01'
    GROUP BY cohort_month
),

users_per_offset AS (      -- users who purchased in each offset month
    SELECT
        cohort_month,
        month_offset,
        COUNT(DISTINCT "user_id") AS users_purchased
    FROM orders_with_offsets
    GROUP BY cohort_month, month_offset
)

SELECT
    TO_CHAR(cohort_month, 'YYYY-MM')                   AS "COHORT_MONTH",
    month_offset + 1                                   AS "MONTH_NUMBER",
    ROUND( users_purchased * 100.0 / cohort_users ,4 ) AS "PERCENT_USERS"
FROM users_per_offset
JOIN cohort_sizes USING (cohort_month)
ORDER BY cohort_month, month_offset;