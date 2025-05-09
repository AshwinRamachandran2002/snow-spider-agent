/*  Cohort-based retention (data through 2022-12-31)
    pct_month1 = % of cohort users who purchased in their first month  (index 0)
    pct_month2 = % of cohort users who purchased in their second month (index 1)
    pct_month3 = % of cohort users who purchased in their third month  (index 2)
    pct_month4 = % of cohort users who purchased in their fourth month (index 3)  */

WITH first_purchase AS (                      -- each user’s very first order (<= 2022-12-31)
    SELECT
        "user_id",
        MIN("created_at") AS "first_purchase_us"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" < 1672531200000000      -- 2022-12-31 23:59:59
    GROUP BY "user_id"
),

cohort_orders AS (                            -- every order these users placed, month-indexed
    SELECT
        fp."user_id",
        TO_CHAR(TO_TIMESTAMP_NTZ(fp."first_purchase_us"/1e6),'YYYYMM')  AS "cohort_month",
        FLOOR( (o."created_at" - fp."first_purchase_us") / 2592000000000 ) AS "month_index"   -- 30-day month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN first_purchase fp               ON o."user_id" = fp."user_id"
    WHERE o."created_at" < 1672531200000000
      AND FLOOR( (o."created_at" - fp."first_purchase_us") / 2592000000000 ) BETWEEN 0 AND 3
),

cohort_counts AS (                            -- distinct-user counts per cohort & month_index
    SELECT
        "cohort_month",
        "month_index",
        COUNT(DISTINCT "user_id") AS "users_cnt"
    FROM cohort_orders
    GROUP BY "cohort_month","month_index"
),

cohort_totals AS (                            -- total users in each cohort (month_index 0)
    SELECT
        "cohort_month",
        MAX(CASE WHEN "month_index" = 0 THEN "users_cnt" END) AS "total_users"
    FROM cohort_counts
    GROUP BY "cohort_month"
)

SELECT
    ct."cohort_month",
    ROUND(100.0 * COALESCE(MAX(CASE WHEN cc."month_index" = 0 THEN cc."users_cnt" END),0) 
                 / ct."total_users", 2) AS "pct_month1",
    ROUND(100.0 * COALESCE(MAX(CASE WHEN cc."month_index" = 1 THEN cc."users_cnt" END),0) 
                 / ct."total_users", 2) AS "pct_month2",
    ROUND(100.0 * COALESCE(MAX(CASE WHEN cc."month_index" = 2 THEN cc."users_cnt" END),0) 
                 / ct."total_users", 2) AS "pct_month3",
    ROUND(100.0 * COALESCE(MAX(CASE WHEN cc."month_index" = 3 THEN cc."users_cnt" END),0) 
                 / ct."total_users", 2) AS "pct_month4"
FROM cohort_totals ct
LEFT JOIN cohort_counts cc
       ON ct."cohort_month" = cc."cohort_month"
GROUP BY ct."cohort_month", ct."total_users"
ORDER BY ct."cohort_month";