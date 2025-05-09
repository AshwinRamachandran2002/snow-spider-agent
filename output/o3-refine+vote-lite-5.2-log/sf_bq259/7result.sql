/* Cohort‑retention (up to 2022): % of users purchasing in their
   1st (cohort), 2nd, 3rd and 4th month after the first purchase */
WITH purchases AS (   -- all non‑cancelled purchases up to 2022‑12‑31
    SELECT
        "user_id",
        CAST(TO_TIMESTAMP_NTZ("created_at" / 1000000) AS DATE) AS purchase_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    WHERE "status" <> 'Cancelled'
      AND "user_id" IS NOT NULL
      AND "created_at" < 1672531200000000          -- 2023‑01‑01 in µs
),  
first_purchase AS (   -- first purchase per user (defines cohort)
    SELECT
        "user_id",
        MIN(purchase_date)                             AS first_purchase_date,
        DATE_TRUNC(month, MIN(purchase_date))          AS cohort_month
    FROM purchases
    GROUP BY "user_id"
    HAVING first_purchase_date < '2023-01-01'
),  
user_activity AS (    -- user × month‑offset (0‑3) in which they bought
    SELECT DISTINCT
        p."user_id",
        fp.cohort_month,
        DATEDIFF(month,
                 fp.cohort_month,
                 DATE_TRUNC(month, p.purchase_date))   AS months_since
    FROM purchases p
    JOIN first_purchase fp USING ("user_id")
    WHERE DATEDIFF(month,
                   fp.cohort_month,
                   DATE_TRUNC(month, p.purchase_date)) BETWEEN 0 AND 3
),  
cohort_sizes AS (     -- users per cohort
    SELECT
        cohort_month,
        COUNT(*) AS cohort_users
    FROM first_purchase
    GROUP BY cohort_month
)  
SELECT
    TO_CHAR(cs.cohort_month, 'YYYY-MM')                                        AS "COHORT_MONTH",
    ROUND(100.0 * SUM(IFF(ua.months_since = 0, 1, 0)) / cs.cohort_users, 4)   AS "PCT_MONTH_1",
    ROUND(100.0 * SUM(IFF(ua.months_since = 1, 1, 0)) / cs.cohort_users, 4)   AS "PCT_MONTH_2",
    ROUND(100.0 * SUM(IFF(ua.months_since = 2, 1, 0)) / cs.cohort_users, 4)   AS "PCT_MONTH_3",
    ROUND(100.0 * SUM(IFF(ua.months_since = 3, 1, 0)) / cs.cohort_users, 4)   AS "PCT_MONTH_4"
FROM cohort_sizes cs
LEFT JOIN user_activity ua
       ON cs.cohort_month = ua.cohort_month
GROUP BY cs.cohort_month, cs.cohort_users
ORDER BY cs.cohort_month;