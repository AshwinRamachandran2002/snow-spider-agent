WITH cohort AS (  -- users whose 1st-ever completed order was in Jan-2020
    SELECT "user_id",
           MIN(TO_DATE(TO_TIMESTAMP("created_at"/1000000))) AS "first_purchase_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" ILIKE '%Complete%'
    GROUP BY "user_id"
    HAVING "first_purchase_date" BETWEEN '2020-01-01' AND '2020-01-31'
),
cohort_size AS (                       -- total users in that cohort
    SELECT COUNT(DISTINCT "user_id") AS "size"
    FROM cohort
),
returns AS (                           -- cohort members who purchased again in Feb-Dec 2020
    SELECT DATE_TRUNC('month',
                      TO_DATE(TO_TIMESTAMP(oi."created_at"/1000000)))        AS "order_month",
           COUNT(DISTINCT oi."user_id")                                     AS "returning_users"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN cohort c
      ON c."user_id" = oi."user_id"
    WHERE oi."status" ILIKE '%Complete%'
      AND TO_DATE(TO_TIMESTAMP(oi."created_at"/1000000))
          BETWEEN '2020-02-01' AND '2020-12-31'
    GROUP BY DATE_TRUNC('month',
                        TO_DATE(TO_TIMESTAMP(oi."created_at"/1000000)))
)
SELECT r."order_month",
       r."returning_users",
       cs."size"                                    AS "cohort_size",
       ROUND(r."returning_users"/cs."size"*100, 2)  AS "retention_pct"
FROM returns r
CROSS JOIN cohort_size cs
ORDER BY r."order_month";