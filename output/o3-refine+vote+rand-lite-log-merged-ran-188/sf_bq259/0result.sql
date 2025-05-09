/*  Cohort-retention (months 0-3) for users whose first completed purchase
    occurred on or before 31-Dec-2022.  Percentages show the share of the
    cohort that bought in each month-offset (month 0 = month of first purchase). */
WITH first_purchase AS (
    SELECT
        "user_id",
        MIN("created_at") AS "first_ts"      -- micro-seconds
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" = 'Complete'
      AND TO_TIMESTAMP("created_at" / 1e6) < TO_TIMESTAMP('2023-01-01')
    GROUP BY "user_id"
),
cohort_activity AS (
    SELECT
        fp."user_id",
        TO_CHAR(DATE_TRUNC(month, TO_TIMESTAMP(fp."first_ts" / 1e6)), 'YYYY-MM')
            AS "cohort_month",
        DATEDIFF(
            month,
            DATE_TRUNC(month, TO_TIMESTAMP(fp."first_ts" / 1e6)),
            DATE_TRUNC(month, TO_TIMESTAMP(o."created_at" / 1e6))
        ) AS "month_since_first"
    FROM first_purchase fp
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
      ON o."user_id" = fp."user_id"
     AND o."status"  = 'Complete'
     AND TO_TIMESTAMP(o."created_at" / 1e6) < TO_TIMESTAMP('2023-01-01')
)
SELECT
    "cohort_month",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN "month_since_first" = 0 THEN "user_id" END)
              / COUNT(DISTINCT "user_id"), 2) AS "pct_m0",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN "month_since_first" = 1 THEN "user_id" END)
              / COUNT(DISTINCT "user_id"), 2) AS "pct_m1",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN "month_since_first" = 2 THEN "user_id" END)
              / COUNT(DISTINCT "user_id"), 2) AS "pct_m2",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN "month_since_first" = 3 THEN "user_id" END)
              / COUNT(DISTINCT "user_id"), 2) AS "pct_m3"
FROM cohort_activity
WHERE "month_since_first" BETWEEN 0 AND 3
GROUP BY "cohort_month"
ORDER BY "cohort_month";