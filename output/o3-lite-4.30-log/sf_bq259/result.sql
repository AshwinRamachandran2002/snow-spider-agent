WITH first_purchase AS (                                  -- each shopper’s 1st real order (through 2022‑12‑31)
    SELECT
        "user_id",
        MIN("created_at")                    AS first_us
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" IN ('Complete','Shipped')
      AND "created_at" < 1672531200000000    -- 2023‑01‑01 00:00:00 in µs
    GROUP BY "user_id"
),
activities AS (                                           -- every later order → month offset 0‑3
    SELECT
        o."user_id",
        TO_CHAR(TO_TIMESTAMP_NTZ(fp.first_us/1000000),'YYYY-MM')          AS first_month,
        DATEDIFF(
            month,
            TO_TIMESTAMP_NTZ(fp.first_us/1000000),
            TO_TIMESTAMP_NTZ(o."created_at"/1000000)
        )                                                                  AS month_number
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN first_purchase fp ON fp."user_id" = o."user_id"
    WHERE o."status" IN ('Complete','Shipped')
      AND o."created_at" < 1672531200000000
      AND DATEDIFF(
            month,
            TO_TIMESTAMP_NTZ(fp.first_us/1000000),
            TO_TIMESTAMP_NTZ(o."created_at"/1000000)
          ) BETWEEN 0 AND 3
),
buyers AS (                                               -- distinct buyers per cohort & month offset
    SELECT
        first_month,
        month_number,
        COUNT(DISTINCT "user_id") AS buyers
    FROM activities
    GROUP BY first_month, month_number
),
cohort AS (                                               -- cohort size = # shoppers with 1st order that month
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(first_us/1000000),'YYYY-MM') AS first_month,
        COUNT(*)                                            AS cohort_size
    FROM first_purchase
    GROUP BY TO_CHAR(TO_TIMESTAMP_NTZ(first_us/1000000),'YYYY-MM')
)
SELECT
    c.first_month                              AS first_purchase_month,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN b.month_number = 0 THEN b.buyers END),0) / c.cohort_size, 4) AS pct_users_month1,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN b.month_number = 1 THEN b.buyers END),0) / c.cohort_size, 4) AS pct_users_month2,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN b.month_number = 2 THEN b.buyers END),0) / c.cohort_size, 4) AS pct_users_month3,
    ROUND(100.0 * COALESCE(MAX(CASE WHEN b.month_number = 3 THEN b.buyers END),0) / c.cohort_size, 4) AS pct_users_month4
FROM cohort c
LEFT JOIN buyers b
       ON b.first_month = c.first_month
GROUP BY c.first_month, c.cohort_size
ORDER BY c.first_month;