WITH purchases AS (   -- every non-cancelled order up to 2022-12-31
    SELECT
        "user_id",
        TO_TIMESTAMP_NTZ("created_at"/1000000)                            AS purchase_ts,
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at"/1000000))       AS purchase_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" IS NOT NULL
      AND "status" <> 'Cancelled'
      AND TO_TIMESTAMP_NTZ("created_at"/1000000) < '2023-01-01'
),
first_purchase AS (   -- first purchase month for every user
    SELECT
        "user_id",
        MIN(purchase_month) AS first_purchase_month
    FROM purchases
    GROUP BY "user_id"
),
purchases_w_cohort AS (   -- months elapsed (0-3) between first and any later purchase
    SELECT
        p."user_id",
        fp.first_purchase_month,
        DATEDIFF('month', fp.first_purchase_month, p.purchase_month) AS months_since_first
    FROM purchases            p
    JOIN first_purchase       fp ON fp."user_id" = p."user_id"
    WHERE DATEDIFF('month', fp.first_purchase_month, p.purchase_month) BETWEEN 0 AND 3
),
cohort_stats AS (   -- head-count for each cohort and month-level repurchase
    SELECT
        first_purchase_month,
        COUNT(DISTINCT "user_id")                                                          AS cohort_size,
        COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN "user_id" END) AS m1_users,   -- first month
        COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN "user_id" END) AS m2_users,   -- second month
        COUNT(DISTINCT CASE WHEN months_since_first = 2 THEN "user_id" END) AS m3_users,   -- third month
        COUNT(DISTINCT CASE WHEN months_since_first = 3 THEN "user_id" END) AS m4_users    -- fourth month
    FROM purchases_w_cohort
    GROUP BY first_purchase_month
)
SELECT
    TO_CHAR(first_purchase_month, 'YYYY-MM')                               AS "cohort_month",
    ROUND(100.0 * m1_users / cohort_size, 4)  AS "pct_first_month",
    ROUND(100.0 * m2_users / cohort_size, 4)  AS "pct_second_month",
    ROUND(100.0 * m3_users / cohort_size, 4)  AS "pct_third_month",
    ROUND(100.0 * m4_users / cohort_size, 4)  AS "pct_fourth_month"
FROM cohort_stats
ORDER BY first_purchase_month;