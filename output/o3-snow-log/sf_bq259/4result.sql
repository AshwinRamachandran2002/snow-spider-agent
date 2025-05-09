WITH orders_2022 AS (          -- all purchases through 31-Dec-2022
    SELECT
        "user_id",
        DATE_TRUNC('month'
          , TO_TIMESTAMP_NTZ("created_at" / 1000000) )          AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) <= '2022-12-31'
      AND "user_id" IS NOT NULL
),  

user_first_purchase AS (       -- each shopper’s first-purchase month (cohort)
    SELECT
        "user_id",
        MIN(order_month)                                        AS cohort_month
    FROM orders_2022
    GROUP BY "user_id"
),  

orders_with_lag AS (           -- month index relative to cohort month
    SELECT
        o."user_id",
        f.cohort_month,
        o.order_month,
        DATEDIFF('month', f.cohort_month, o.order_month)        AS month_index
    FROM orders_2022     o
    JOIN user_first_purchase f
          ON o."user_id" = f."user_id"
    WHERE DATEDIFF('month', f.cohort_month, o.order_month) BETWEEN 0 AND 3
),  

cohort_user_counts AS (        -- distinct shoppers active in months 0-3
    SELECT
        cohort_month,
        COUNT(DISTINCT CASE WHEN month_index = 0 THEN "user_id" END) AS users_m1,
        COUNT(DISTINCT CASE WHEN month_index = 1 THEN "user_id" END) AS users_m2,
        COUNT(DISTINCT CASE WHEN month_index = 2 THEN "user_id" END) AS users_m3,
        COUNT(DISTINCT CASE WHEN month_index = 3 THEN "user_id" END) AS users_m4
    FROM orders_with_lag
    GROUP BY cohort_month
),  

cohort_sizes AS (              -- size of every monthly cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id")                                AS cohort_size
    FROM user_first_purchase
    GROUP BY cohort_month
)

SELECT
    cs.cohort_month,
    ROUND(cuc.users_m1 * 100.0 / cs.cohort_size, 4) AS pct_users_month_1,
    ROUND(cuc.users_m2 * 100.0 / cs.cohort_size, 4) AS pct_users_month_2,
    ROUND(cuc.users_m3 * 100.0 / cs.cohort_size, 4) AS pct_users_month_3,
    ROUND(cuc.users_m4 * 100.0 / cs.cohort_size, 4) AS pct_users_month_4
FROM cohort_sizes cs
LEFT JOIN cohort_user_counts cuc
       ON cs.cohort_month = cuc.cohort_month
ORDER BY cs.cohort_month;