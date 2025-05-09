WITH valid_orders AS (      -- keep only real purchases up to the end of 2022
    SELECT
        "user_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000))  AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
      AND TO_TIMESTAMP_NTZ("created_at" / 1000000) < '2023-01-01'
      AND "user_id" IS NOT NULL
),

user_cohorts AS (           -- first‑purchase month for every customer
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM valid_orders
    GROUP BY "user_id"
),

orders_with_offset AS (     -- distance (in months) from first purchase
    SELECT
        v."user_id",
        u.cohort_month,
        DATEDIFF('month', u.cohort_month, v.order_month) AS month_offset
    FROM valid_orders v
    JOIN user_cohorts u
          ON v."user_id" = u."user_id"
    WHERE DATEDIFF('month', u.cohort_month, v.order_month) BETWEEN 0 AND 3
)

SELECT
    cohort_month,
    ROUND( COUNT(DISTINCT CASE WHEN month_offset = 0 THEN "user_id" END)
           / COUNT(DISTINCT "user_id") * 100 , 4) AS pct_month_1,   -- month of first purchase
    ROUND( COUNT(DISTINCT CASE WHEN month_offset = 1 THEN "user_id" END)
           / COUNT(DISTINCT "user_id") * 100 , 4) AS pct_month_2,   -- second month
    ROUND( COUNT(DISTINCT CASE WHEN month_offset = 2 THEN "user_id" END)
           / COUNT(DISTINCT "user_id") * 100 , 4) AS pct_month_3,   -- third month
    ROUND( COUNT(DISTINCT CASE WHEN month_offset = 3 THEN "user_id" END)
           / COUNT(DISTINCT "user_id") * 100 , 4) AS pct_month_4    -- fourth month
FROM orders_with_offset
GROUP BY cohort_month
ORDER BY cohort_month;