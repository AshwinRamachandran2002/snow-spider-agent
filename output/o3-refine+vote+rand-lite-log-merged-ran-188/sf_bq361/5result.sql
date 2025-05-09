/* ---------------------------------------------------------------
   Cohort: users whose FIRST-EVER order was placed in January 2020
   Goal   : For every later month in 2020 (Feb-Dec), show
            – # of those cohort users who placed ≥1 order
            – cohort size
            – proportion that returned
---------------------------------------------------------------- */
WITH cohort AS (          -- January-2020 first-purchase users
    SELECT  "user_id"
    FROM   (
        SELECT "user_id",
               MIN("created_at") AS first_order_ts
        FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
        GROUP BY "user_id"
    )
    WHERE  first_order_ts BETWEEN 1577836800000000   -- 01-Jan-2020 00:00:00
                             AND     1580515199000000   -- 31-Jan-2020 23:59:59
),  

monthly_activity AS (     -- cohort users active each month Feb-Dec-2020
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at"/1e6)) AS "order_month",
        COUNT(DISTINCT "user_id")                              AS "active_users"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "user_id" IN (SELECT "user_id" FROM cohort)
      AND "created_at" BETWEEN 1577836800000000  /* 01-Jan-2020 */
                          AND 1609459199000000  /* 31-Dec-2020 */
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at"/1e6)) > '2020-01-01'
    GROUP BY 1
)

SELECT
    ma."order_month",
    ma."active_users",
    c."cohort_size",
    ROUND(ma."active_users" / c."cohort_size", 4) AS "returning_prop"
FROM monthly_activity  ma
CROSS JOIN (
    SELECT COUNT(*) AS "cohort_size" FROM cohort
) c
ORDER BY ma."order_month";