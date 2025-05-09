/* Month-over-month retention up to the end of 2022
   “first month” = month of the user’s very first order                */

WITH first_purchase AS (      -- 1. first order timestamp for every user
    SELECT
        "user_id",
        MIN("created_at") AS first_purchase_at
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" < 1672531200000000          -- before 2023-01-01
    GROUP BY "user_id"
),

cohorts AS (                  -- 2. cohort month (YYYY-MM) for each user
    SELECT
        fp."user_id",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(fp.first_purchase_at / 1000000)
        )                     AS cohort_month,
        fp.first_purchase_at
    FROM first_purchase fp
),

user_activity AS (            -- 3. each purchase’s distance in months
    SELECT
        o."user_id",
        c.cohort_month,
        FLOOR( (o."created_at" - c.first_purchase_at) / 2592000000000 )
                                AS nth_month               -- 30 days in µs
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN cohorts c
          ON c."user_id" = o."user_id"
    WHERE o."created_at" < 1672531200000000
      AND FLOOR( (o."created_at" - c.first_purchase_at) / 2592000000000 )
            BETWEEN 0 AND 3                             -- first four months
),

cohort_sizes AS (             -- 4. number of users in every cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_users
    FROM cohorts
    GROUP BY cohort_month
),

retention_raw AS (            -- 5. distinct users active each period
    SELECT
        cohort_month,
        nth_month,
        COUNT(DISTINCT "user_id") AS active_users
    FROM user_activity
    GROUP BY cohort_month, nth_month
),

retention_pct AS (            -- 6. convert counts to percentages
    SELECT
        r.cohort_month,
        r.nth_month,
        ROUND(100.0 * r.active_users / cs.cohort_users, 2) AS pct_users
    FROM retention_raw r
    JOIN cohort_sizes cs USING (cohort_month)
)

/* 7. pivot so each cohort has four percentage columns (month 1-4) */
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM')                      AS cohort_month,
    MAX(CASE WHEN nth_month = 0 THEN pct_users END)       AS pct_month_1,
    MAX(CASE WHEN nth_month = 1 THEN pct_users END)       AS pct_month_2,
    MAX(CASE WHEN nth_month = 2 THEN pct_users END)       AS pct_month_3,
    MAX(CASE WHEN nth_month = 3 THEN pct_users END)       AS pct_month_4
FROM retention_pct
GROUP BY cohort_month
ORDER BY cohort_month;