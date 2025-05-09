WITH orders AS (
    /* all purchases up to 31-Dec-2022, converted to month bucket */
    SELECT
        "user_id",
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("created_at" / 1000000)      -- micro-seconds → seconds
        )                            AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" < DATE_PART(EPOCH , '2023-01-01'::TIMESTAMP_NTZ) * 1000000
),
user_first_purchase AS (
    /* month of each user’s very first purchase (cohort month) */
    SELECT
        "user_id",
        MIN(order_month) AS cohort_month
    FROM orders
    GROUP BY "user_id"
),
cohort_activity AS (
    /* months-since-first purchase for every order (keep first 4 months) */
    SELECT
        o."user_id",
        u.cohort_month,
        DATEDIFF('month', u.cohort_month, o.order_month) AS months_since_first
    FROM orders o
    JOIN user_first_purchase u
          ON o."user_id" = u."user_id"
    WHERE DATEDIFF('month', u.cohort_month, o.order_month) BETWEEN 0 AND 3
),
cohort_counts AS (
    /* users active in each month-since bucket */
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN months_since_first = 0 THEN "user_id" END) AS m0_users,
        COUNT(DISTINCT CASE WHEN months_since_first = 1 THEN "user_id" END) AS m1_users,
        COUNT(DISTINCT CASE WHEN months_since_first = 2 THEN "user_id" END) AS m2_users,
        COUNT(DISTINCT CASE WHEN months_since_first = 3 THEN "user_id" END) AS m3_users,
        COUNT(DISTINCT "user_id")                                            AS total_users
    FROM cohort_activity
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    ROUND(100.0 * m0_users / total_users, 4) AS pct_month1,   -- month of first purchase
    ROUND(100.0 * m1_users / total_users, 4) AS pct_month2,   -- 2nd month since first
    ROUND(100.0 * m2_users / total_users, 4) AS pct_month3,   -- 3rd month
    ROUND(100.0 * m3_users / total_users, 4) AS pct_month4    -- 4th month
FROM cohort_counts
ORDER BY cohort_month;