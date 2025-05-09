/*-----------------------------------------------------------
  Cohort: users whose FIRST completed purchase occurred
  between 2020-01-01 and 2020-01-31 (UTC).
  For every subsequent month in 2020 (Feb-Dec),
  calculate the share of that cohort that placed
  at least one additional completed order.
-----------------------------------------------------------*/
WITH cohort AS (               -- 1) identify the Jan-2020 cohort
    SELECT
        "user_id",
        MIN("created_at") AS first_purchase_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" ILIKE '%Complete%'
    GROUP BY "user_id"
    HAVING first_purchase_ts BETWEEN 1577836800000000    -- 2020-01-01 00:00:00
                                AND 1580515199000000    -- 2020-01-31 23:59:59
), cohort_size AS (            -- 2) cache cohort size
    SELECT COUNT(*) AS size
    FROM cohort
), subsequent_orders AS (      -- 3) cohort orders placed Feb-Dec-2020
    SELECT
        o."user_id",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
        ) AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN cohort c
      ON o."user_id" = c."user_id"
    WHERE o."status" ILIKE '%Complete%'
      AND o."created_at" >= 1580515200000000              -- 2020-02-01 00:00:00
      AND o."created_at" <  1609459200000000              -- 2021-01-01 00:00:00
)
SELECT
    order_month,
    COUNT(DISTINCT "user_id")                       AS returning_users,
    cs.size                                         AS cohort_size,
    ROUND(COUNT(DISTINCT "user_id")::FLOAT / cs.size, 4)
                                                    AS proportion_returned
FROM subsequent_orders
CROSS JOIN cohort_size cs
GROUP BY order_month, cs.size
ORDER BY order_month NULLS LAST;