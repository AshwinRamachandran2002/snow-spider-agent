WITH first_purchase AS (      -- earliest non‑cancelled line‑item per user (≤ 2022‑12‑31)
    SELECT
        "user_id",
        MIN("created_at") AS first_purchase_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" <> 'Cancelled'
      AND "created_at" < 1672531200000000
    GROUP BY "user_id"
),
cohorts AS (                  -- cohort month (YYYY‑MM) for every user
    SELECT
        fp."user_id",
        TO_CHAR(TO_TIMESTAMP_NTZ(fp.first_purchase_ts / 1000000), 'YYYY-MM') AS first_purchase_month
    FROM first_purchase fp
),
cohort_size AS (              -- number of users in each cohort
    SELECT
        first_purchase_month,
        COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY first_purchase_month
),
purchases AS (                -- all subsequent purchases within 4‑month window
    SELECT
        oi."user_id",
        FLOOR(
            DATEDIFF(
                'day',
                TO_TIMESTAMP_NTZ(fp.first_purchase_ts / 1000000),
                TO_TIMESTAMP_NTZ(oi."created_at"      / 1000000)
            ) / 30
        ) AS month_offset
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN first_purchase fp ON oi."user_id" = fp."user_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."created_at" < 1672531200000000
      AND FLOOR(
            DATEDIFF(
                'day',
                TO_TIMESTAMP_NTZ(fp.first_purchase_ts / 1000000),
                TO_TIMESTAMP_NTZ(oi."created_at"      / 1000000)
            ) / 30
          ) BETWEEN 0 AND 3
)
SELECT
    cs.first_purchase_month,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.month_offset = 0 THEN p."user_id" END) / cs.cohort_size, 4) AS pct_users_month1,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.month_offset = 1 THEN p."user_id" END) / cs.cohort_size, 4) AS pct_users_month2,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.month_offset = 2 THEN p."user_id" END) / cs.cohort_size, 4) AS pct_users_month3,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN p.month_offset = 3 THEN p."user_id" END) / cs.cohort_size, 4) AS pct_users_month4
FROM cohort_size cs
LEFT JOIN cohorts   c ON c.first_purchase_month = cs.first_purchase_month
LEFT JOIN purchases p ON p."user_id"            = c."user_id"
GROUP BY cs.first_purchase_month, cs.cohort_size
ORDER BY cs.first_purchase_month;