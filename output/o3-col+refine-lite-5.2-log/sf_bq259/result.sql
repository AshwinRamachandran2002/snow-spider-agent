/*  Cohort‑style retention – share of shoppers active in the first
    four months (0‑3) counted from their very first completed purchase.
    Data limited to orders created before 2023‑01‑01.              */

WITH first_purchase AS (                  -- month of each shopper’s initial purchase
    SELECT  "user_id",
            DATE_TRUNC('month',
                       TO_TIMESTAMP(MIN("created_at")/1000000)) AS "first_purchase_month"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE   "status" = 'Complete'
      AND   TO_TIMESTAMP("created_at"/1000000) < '2023-01-01'
    GROUP BY "user_id"
),
filtered_orders AS (                      -- all completed purchases (≤ 2022‑12‑31)
    SELECT  o."user_id",
            DATE_TRUNC('month',
                       TO_TIMESTAMP(o."created_at"/1000000)) AS "order_month"
    FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    WHERE   o."status" = 'Complete'
      AND   TO_TIMESTAMP(o."created_at"/1000000) < '2023-01-01'
),
activity AS (                             -- month offsets 0‑3 in which a shopper bought
    SELECT  fp."user_id",
            DATEDIFF('month',
                     fp."first_purchase_month",
                     fo."order_month")     AS "month_offset"
    FROM    first_purchase  fp
    JOIN    filtered_orders fo
           ON fp."user_id" = fo."user_id"
    WHERE   DATEDIFF('month',
                     fp."first_purchase_month",
                     fo."order_month") BETWEEN 0 AND 3
    GROUP BY fp."user_id", "month_offset"
),
totals AS (                               -- cohort size (all shoppers considered)
    SELECT COUNT(DISTINCT "user_id") AS "total_users"
    FROM   first_purchase
)

SELECT  a."month_offset"         AS "relative_month",
        ROUND(
            100 * COUNT(DISTINCT a."user_id") / t."total_users",
            2
        )                       AS "pct_users"
FROM    activity a
CROSS JOIN totals t
GROUP BY a."month_offset", t."total_users"
ORDER BY a."month_offset";