/*  Proportion of the January-2020 first-purchase cohort that returned
    in each subsequent month of 2020 (February-December)               */

WITH first_purchase AS (          -- first order ever for every user
    SELECT
        "user_id",
        MIN(TO_TIMESTAMP_LTZ("created_at" / 1e6)) AS first_purchase_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY "user_id"
),

jan2020_cohort AS (               -- users whose very first order was in Jan-2020
    SELECT "user_id"
    FROM   first_purchase
    WHERE  first_purchase_ts >= '2020-01-01'
       AND first_purchase_ts <  '2020-02-01'
),

months AS (                       -- list of months Feb-2020 … Dec-2020
    SELECT DATE_TRUNC('month',
                      DATEADD(month, seq4(), TO_DATE('2020-02-01'))
           ) AS month_start
    FROM   TABLE(GENERATOR(ROWCOUNT => 11))        -- 11 months
),

returns AS (                      -- cohort users who ordered again, by month
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_LTZ(o."created_at" / 1e6)
               )                                AS order_month,
        COUNT(DISTINCT o."user_id")            AS returning_users
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN   jan2020_cohort c
           USING ("user_id")
    WHERE  TO_TIMESTAMP_LTZ(o."created_at" / 1e6) >= '2020-02-01'
      AND  TO_TIMESTAMP_LTZ(o."created_at" / 1e6) <  '2021-01-01'
    GROUP  BY 1
)

SELECT
    m.month_start,
    COALESCE(r.returning_users, 0)                                       AS returning_users,
    ROUND(
          COALESCE(r.returning_users, 0) :: FLOAT
          / (SELECT COUNT(*) FROM jan2020_cohort)
         ,4)                                                             AS returning_rate
FROM   months  m
LEFT   JOIN returns r
       ON m.month_start = r.order_month
ORDER  BY m.month_start;