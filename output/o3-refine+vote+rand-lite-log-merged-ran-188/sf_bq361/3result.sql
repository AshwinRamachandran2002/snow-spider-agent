/*  Proportion of the January-2020 cohort that returned in each subsequent
    month of 2020 (Feb-2020 .. Dec-2020)                                  */

WITH first_purchase AS (        -- first order ever for every shopper
    SELECT "user_id",
           MIN("created_at") AS "first_purchase_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY "user_id"
),

jan_2020_cohort AS (            -- users whose first purchase was in Jan-2020
    SELECT "user_id"
    FROM first_purchase
    WHERE "first_purchase_at" >= 1577836800000000      -- 2020-01-01 00:00:00 µs
      AND "first_purchase_at" <  1580515200000000      -- 2020-02-01 00:00:00 µs
),

subsequent_orders AS (          -- purchases these users made Feb-2020 .. Dec-2020
    SELECT
        TO_CHAR(
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)),
            'YYYY-MM'
        )                             AS "order_month",
        COUNT(DISTINCT o."user_id")   AS "returning_users"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN jan_2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE o."created_at" >= 1580515200000000          -- 2020-02-01
      AND o."created_at" <  1609459200000000          -- 2021-01-01
    GROUP BY 1
)

SELECT
    "order_month",
    "returning_users",
    (SELECT COUNT(*) FROM jan_2020_cohort)                         AS "cohort_size",
    ROUND(
        "returning_users" / (SELECT COUNT(*) FROM jan_2020_cohort)::FLOAT,
        4
    )                                                              AS "retention_rate"
FROM subsequent_orders
ORDER BY "order_month" ASC;