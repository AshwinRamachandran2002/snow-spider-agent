/* Proportion of January-2020 first-purchase cohort who returned in each
   subsequent month of calendar-year 2020                                   */

WITH first_purchase AS (          -- each shopper’s very first order time-stamp
    SELECT
        "user_id",
        MIN("created_at") AS "first_purchase_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
),

jan2020_cohort AS (               -- users whose first order fell in Jan-2020
    SELECT "user_id"
    FROM   first_purchase
    WHERE  TO_TIMESTAMP("first_purchase_ts"/1e6) >= '2020-01-01'
       AND TO_TIMESTAMP("first_purchase_ts"/1e6) <  '2020-02-01'
),

cohort_size AS (                  -- total number of cohort users
    SELECT COUNT(*) AS "n_users"
    FROM   jan2020_cohort
),

monthly_returns AS (              -- month-by-month count of cohort users ordering again
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(o."created_at"/1e6)) AS "order_month",
        COUNT(DISTINCT o."user_id")                           AS "returning_users"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN   jan2020_cohort c
      ON   o."user_id" = c."user_id"
    WHERE  TO_TIMESTAMP(o."created_at"/1e6) >= '2020-02-01'
      AND  TO_TIMESTAMP(o."created_at"/1e6) <  '2021-01-01'
    GROUP  BY 1
)

SELECT
    m."order_month",
    m."returning_users",
    ROUND( m."returning_users" / s."n_users", 6 ) AS "proportion_returned"
FROM   monthly_returns m
CROSS  JOIN cohort_size s
ORDER  BY m."order_month";