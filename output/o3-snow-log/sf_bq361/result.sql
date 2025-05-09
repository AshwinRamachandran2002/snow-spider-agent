/*  Proportion of January-2020 first-time purchasers who returned
    in every later month of 2020                                           */

WITH first_purchase AS (        -- each user’s very first order time stamp
    SELECT
        "user_id",
        MIN(TO_TIMESTAMP("created_at" / 1000000)) AS "first_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
),

jan_cohort AS (                 -- users whose very first order was in Jan-2020
    SELECT
        "user_id"
    FROM first_purchase
    WHERE TO_CHAR("first_ts", 'YYYY-MM') = '2020-01'
),

cohort_size AS (                -- total cohort size
    SELECT COUNT(*) AS "cohort_size" FROM jan_cohort
),

monthly_returns AS (            -- how many cohort users ordered again each month
    SELECT
        TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM') AS "month_2020",
        COUNT(DISTINCT o."user_id")                                AS "returning_users"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN jan_cohort j
      ON j."user_id" = o."user_id"
    WHERE TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY')  = '2020'
      AND TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM') > '2020-01'
    GROUP BY TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM')
)

SELECT
    m."month_2020",
    m."returning_users",
    c."cohort_size",
    ROUND(m."returning_users" / c."cohort_size", 4) AS "return_prop"
FROM monthly_returns m
CROSS JOIN cohort_size c
ORDER BY m."month_2020";