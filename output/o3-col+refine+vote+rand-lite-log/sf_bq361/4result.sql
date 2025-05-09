/*  Proportion of the January-2020 first-purchase cohort that returned in each
    subsequent month of 2020 (using ORDER_ITEMS)                                   */

WITH jan20_cohort AS (           -- users whose FIRST purchase occurred in Jan-2020
    SELECT "user_id"
    FROM (
        SELECT "user_id",
               MIN("created_at") AS first_ts
        FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
        GROUP BY "user_id"
    )
    WHERE first_ts BETWEEN 1577836800000000        -- 2020-01-01 00:00:00
                       AND 1580515199000000        -- 2020-01-31 23:59:59
),

monthly_returns AS (             -- how many of those users bought again each month
    SELECT
        TO_CHAR(
            TO_TIMESTAMP_NTZ("created_at"/1000000),
            'YYYY-MM'
        )                                             AS yyyy_mm,
        COUNT(DISTINCT "user_id")                     AS returning_users
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
    WHERE "created_at" BETWEEN 1580515200000000      -- 2020-02-01
                           AND 1609459199000000      -- 2020-12-31 23:59:59
      AND "user_id" IN (SELECT "user_id" FROM jan20_cohort)
    GROUP BY yyyy_mm
)

SELECT
    mr.yyyy_mm,
    mr.returning_users,
    cs.cohort_size,
    ROUND(mr.returning_users * 1.0 / cs.cohort_size, 4) AS return_rate
FROM monthly_returns mr
CROSS JOIN (SELECT COUNT(*) AS cohort_size FROM jan20_cohort) cs
ORDER BY mr.yyyy_mm;