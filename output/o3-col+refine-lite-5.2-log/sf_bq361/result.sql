WITH first_orders AS (
    /* find each shopper’s very first order */
    SELECT
        "user_id",
        MIN("created_at") AS "first_order_ts_micro"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    GROUP BY "user_id"
),
jan_2020_cohort AS (
    /* keep only users whose first purchase fell in January‑2020 */
    SELECT
        "user_id"
    FROM first_orders
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("first_order_ts_micro" / 1000000))
          BETWEEN '2020-01-01' AND '2020-01-31'
),
cohort_size AS (
    SELECT COUNT(*) AS "num_users" FROM jan_2020_cohort
),
returning_users AS (
    /* those cohort users who bought again after January within 2020 */
    SELECT COUNT(DISTINCT o."user_id") AS "num_returning"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN jan_2020_cohort c
      ON o."user_id" = c."user_id"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) >  '2020-01-31'
      AND TO_DATE(TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) <= '2020-12-31'
)
SELECT
    ROUND(r."num_returning" / s."num_users", 4) AS "returning_proportion_2020"
FROM returning_users r
CROSS JOIN cohort_size s;