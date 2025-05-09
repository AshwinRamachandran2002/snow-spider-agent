/* Cohort-based user retention (months 0-3) for orders through 2022-12-31 */

WITH first_purchase AS (          -- first “Complete” order for every user
    SELECT
        "user_id",
        MIN("created_at") AS first_purchase_us
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" = 'Complete'
      AND "created_at" < 1672531200000000          -- 2023-01-01 00:00:00 (µs)
    GROUP BY "user_id"
),

cohort AS (                       -- add cohort-month to each user
    SELECT
        fp."user_id",
        fp.first_purchase_us,
        TO_CHAR(TO_TIMESTAMP_NTZ(fp.first_purchase_us/1000000), 'YYYY-MM')
            AS cohort_month
    FROM first_purchase fp
),

cohort_sizes AS (                 -- denominator: users in each cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS total_users
    FROM cohort
    GROUP BY cohort_month
),

purchase_events AS (              -- every qualifying purchase with month lag
    SELECT
        c.cohort_month,
        DATEDIFF(
            month,
            TO_TIMESTAMP_NTZ(c.first_purchase_us/1000000),
            TO_TIMESTAMP_NTZ(o."created_at"/1000000)
        ) AS months_since_first_purchase,
        o."user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN cohort c
      ON o."user_id" = c."user_id"
    WHERE o."status" = 'Complete'
      AND o."created_at" < 1672531200000000
),

retention_raw AS (                -- users who purchased again in months 0-3
    SELECT
        cohort_month,
        months_since_first_purchase,
        COUNT(DISTINCT "user_id") AS users_with_purchase
    FROM purchase_events
    WHERE months_since_first_purchase BETWEEN 0 AND 3
    GROUP BY cohort_month, months_since_first_purchase
),

months AS (                       -- helper rows: 0,1,2,3
    SELECT 0 AS m UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
),

retention AS (                    -- join to get 0-values where needed
    SELECT
        cs.cohort_month,
        m.m AS months_since_first_purchase,
        COALESCE(rr.users_with_purchase, 0) AS users_with_purchase,
        cs.total_users,
        ROUND(
            COALESCE(rr.users_with_purchase, 0) * 100.0 / cs.total_users,
            4
        ) AS retention_pct
    FROM cohort_sizes cs
    CROSS JOIN months m
    LEFT JOIN retention_raw rr
           ON  cs.cohort_month = rr.cohort_month
           AND m.m              = rr.months_since_first_purchase
)

SELECT
    cohort_month,
    months_since_first_purchase,
    retention_pct               -- percentage of cohort’s users who purchased
FROM retention
ORDER BY cohort_month, months_since_first_purchase;