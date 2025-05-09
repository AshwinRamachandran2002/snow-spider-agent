WITH firsts AS (
    SELECT 
        "user_id",
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(MIN("created_at")/1e6)) AS "first_purchase_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" < 1672531200000000           -- up to 2022‑12‑31 23:59:59
      AND "status" IN ('Complete','Shipped','Processing')
    GROUP BY "user_id"
),
cohort_size AS (
    SELECT 
        "first_purchase_month",
        COUNT(DISTINCT "user_id") AS "cohort_users"
    FROM firsts
    GROUP BY "first_purchase_month"
),
activity AS (
    SELECT  
        o."user_id",
        f."first_purchase_month",
        DATEDIFF(
            'month',
            f."first_purchase_month",
            DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at"/1e6))
        ) + 1 AS "month_number"                     -- 1 = month of first purchase
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN firsts f ON o."user_id" = f."user_id"
    WHERE o."created_at" < 1672531200000000
      AND o."status" IN ('Complete','Shipped','Processing')
      AND DATEDIFF(
            'month',
            f."first_purchase_month",
            DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at"/1e6))
        ) + 1 BETWEEN 1 AND 4                      -- keep only first 4 months
)
SELECT 
    TO_CHAR("first_purchase_month",'YYYY-MM')                                AS "first_purchase_month",
    ROUND(COUNT(DISTINCT CASE WHEN "month_number" = 1 THEN "user_id" END)
          * 100.0 / MAX("cohort_users"), 4)                                  AS "pct_users_month1",
    ROUND(COUNT(DISTINCT CASE WHEN "month_number" = 2 THEN "user_id" END)
          * 100.0 / MAX("cohort_users"), 4)                                  AS "pct_users_month2",
    ROUND(COUNT(DISTINCT CASE WHEN "month_number" = 3 THEN "user_id" END)
          * 100.0 / MAX("cohort_users"), 4)                                  AS "pct_users_month3",
    ROUND(COUNT(DISTINCT CASE WHEN "month_number" = 4 THEN "user_id" END)
          * 100.0 / MAX("cohort_users"), 4)                                  AS "pct_users_month4"
FROM activity
JOIN cohort_size USING("first_purchase_month")
GROUP BY "first_purchase_month"
ORDER BY "first_purchase_month";