WITH complete_orders AS (
    SELECT 
        "user_id",
        TO_TIMESTAMP_NTZ("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" = 'Complete'
),
-- users whose FIRST‑EVER completed order was in Jan‑2020
jan2020_cohort AS (
    SELECT 
        "user_id"
    FROM (
        SELECT 
            "user_id",
            MIN(order_ts) AS first_order_ts
        FROM complete_orders
        GROUP BY "user_id"
    )
    WHERE DATE_TRUNC('month', first_order_ts) = DATE '2020-01-01'
),
-- every later month in 2020 when any of those users bought again
cohort_activity_2020 AS (
    SELECT
        o."user_id",
        DATE_TRUNC('month', o.order_ts) AS activity_month
    FROM complete_orders o
    JOIN jan2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE DATE_TRUNC('year', o.order_ts) = DATE '2020-01-01'
      AND DATE_TRUNC('month', o.order_ts) > DATE '2020-01-01'   -- months AFTER January
)
SELECT
    TO_CHAR(activity_month, 'YYYY-MM')               AS "month",
    COUNT(DISTINCT "user_id")                        AS "active_users",
    ROUND(
        COUNT(DISTINCT "user_id") 
        / (SELECT COUNT(*) FROM jan2020_cohort)::FLOAT
    , 4)                                             AS "proportion_of_cohort"
FROM cohort_activity_2020
GROUP BY activity_month
ORDER BY activity_month;