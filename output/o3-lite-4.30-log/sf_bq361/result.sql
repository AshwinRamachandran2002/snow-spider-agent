WITH firsts AS (
    SELECT "user_id",
           MIN("created_at") AS "first_order_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    GROUP BY "user_id"
), jan20_cohort AS (
    /* Users whose very first purchase happened in Jan‑2020 */
    SELECT "user_id"
    FROM firsts
    WHERE "first_order_ts" BETWEEN 1577836800000000         -- 2020‑01‑01 00:00:00
                               AND     1580515200000000     -- 2020‑02‑01 00:00:00
), cohort_size AS (
    SELECT COUNT(*) AS "total_users"
    FROM jan20_cohort
), orders_2020 AS (
    /* Later‑in‑2020 orders placed by those cohort users */
    SELECT o."user_id",
           TO_CHAR(TO_TIMESTAMP(o."created_at"/1000000), 'YYYY‑MM') AS "order_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN jan20_cohort c
      ON o."user_id" = c."user_id"
    WHERE o."created_at" BETWEEN 1580515200000000          -- 2020‑02‑01
                            AND     1609459200000000        -- 2021‑01‑01
), month_counts AS (
    SELECT "order_month",
           COUNT(DISTINCT "user_id") AS "returning_users"
    FROM orders_2020
    GROUP BY "order_month"
)
SELECT m."order_month" AS "month",
       ROUND(m."returning_users"::FLOAT / cs."total_users", 4) AS "proportion_returned"
FROM month_counts m
CROSS JOIN cohort_size cs
ORDER BY "month";