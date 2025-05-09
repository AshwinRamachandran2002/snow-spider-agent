WITH orders_2022 AS (   -- all non‑cancelled orders up to 31‑Dec‑2022
    SELECT
        "user_id",
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("created_at"/1000000))  AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "user_id" IS NOT NULL
      AND "status" <> 'Cancelled'
      AND TO_TIMESTAMP_NTZ("created_at"/1000000) < '2023-01-01'
),

first_purchase AS (     -- first‐purchase date & cohort for every user
    SELECT
        "user_id",
        MIN(order_date)                                  AS first_purchase_date,
        DATE_TRUNC('month', MIN(order_date))             AS cohort_month
    FROM orders_2022
    GROUP BY "user_id"
),

orders_with_offset AS ( -- months 0‑3 (i.e. first‑four months) since first purchase
    SELECT
        o."user_id",
        f.cohort_month,
        DATEDIFF('month', f.first_purchase_date, o.order_date) AS month_offset
    FROM orders_2022 o
    JOIN first_purchase f
      ON f."user_id" = o."user_id"
    WHERE DATEDIFF('month', f.first_purchase_date, o.order_date) BETWEEN 0 AND 3
),

cohort_size AS (        -- total users in every cohort month
    SELECT
        cohort_month,
        COUNT(DISTINCT "user_id") AS cohort_users
    FROM first_purchase
    GROUP BY cohort_month
),

retention AS (          -- users purchasing in each offset month
    SELECT
        cohort_month,
        month_offset + 1                    AS month_number_since_first, -- 1‑4
        COUNT(DISTINCT "user_id")           AS users_active
    FROM orders_with_offset
    GROUP BY cohort_month, month_offset
)

SELECT
    TO_CHAR(cohort_month, 'YYYY-MM')        AS cohort_month,
    month_number_since_first,               -- 1 = first month, 2 = second, etc.
    ROUND(users_active * 100.0 / cohort_users, 4) AS percentage_users
FROM retention
JOIN cohort_size USING (cohort_month)
ORDER BY cohort_month, month_number_since_first;