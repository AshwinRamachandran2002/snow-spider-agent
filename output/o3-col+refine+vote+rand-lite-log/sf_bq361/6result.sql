/*  Proportion of Jan-2020 cohort users who placed at least one additional order
    in each subsequent month of 2020                                           */
WITH first_order AS (           -- first purchase date for every user
    SELECT 
        "user_id",
        MIN( TO_DATE( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) ) 
            AS "first_purchase_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY "user_id"
), jan2020_cohort AS (          -- users whose very first order was in Jan-2020
    SELECT "user_id"
    FROM first_order
    WHERE "first_purchase_date" BETWEEN '2020-01-01' AND '2020-01-31'
), cohort_size AS (             -- size of the cohort
    SELECT COUNT(*) AS "total_users" 
    FROM jan2020_cohort
), cohort_activity AS (         -- cohort users active in Feb-Dec 2020
    SELECT 
        TO_CHAR( TO_DATE( TO_TIMESTAMP_NTZ(o."created_at" / 1000000) ),
                 'YYYY-MM' )                         AS "order_month",
        COUNT( DISTINCT o."user_id" )                AS "active_users"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN jan2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE TO_DATE( TO_TIMESTAMP_NTZ(o."created_at" / 1000000) )
          BETWEEN '2020-02-01' AND '2020-12-31'      -- months after January
    GROUP BY "order_month"
)
SELECT 
    a."order_month",
    a."active_users",
    s."total_users",
    ROUND( a."active_users" / s."total_users", 4 )   AS "retention_rate"
FROM cohort_activity a
CROSS JOIN cohort_size s
ORDER BY a."order_month";