/* --------------------------------------------------------------
   Retention-style percentages for the 1st-to-4th months
   after a user’s first completed purchase (cohort ≤ 2022-12).
----------------------------------------------------------------*/
WITH completed_orders AS (      /* only “real” purchases                     */
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP_NTZ("created_at"/1e6))        AS order_dt
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" ILIKE '%complete%'
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_at"/1e6)) <= '2022-12-31'
),

first_purchase AS (             /* first purchase date per user              */
    SELECT
        "user_id",
        MIN(order_dt)                                   AS first_dt
    FROM completed_orders
    GROUP BY "user_id"
),

orders_with_offset AS (         /* retain only offsets 0-3 (months)          */
    SELECT
        fp."user_id",
        DATE_TRUNC('month', fp.first_dt)                 AS cohort_month,
        DATEDIFF(
            month,
            DATE_TRUNC('month', fp.first_dt),
            DATE_TRUNC('month', co.order_dt)
        )                                                AS month_offset
    FROM completed_orders   co
    JOIN first_purchase     fp ON fp."user_id" = co."user_id"
    WHERE DATEDIFF(
              month,
              DATE_TRUNC('month', fp.first_dt),
              DATE_TRUNC('month', co.order_dt)
          ) BETWEEN 0 AND 3
),

cohort_size AS (                /* total users in each cohort month          */
    SELECT
        DATE_TRUNC('month', first_dt)                    AS cohort_month,
        COUNT(DISTINCT "user_id")                        AS users_in_cohort
    FROM first_purchase
    GROUP BY DATE_TRUNC('month', first_dt)
),

cohort_hits AS (                /* users purchasing in each offset month     */
    SELECT
        cohort_month,
        month_offset,
        COUNT(DISTINCT "user_id")                        AS users_w_purchase
    FROM orders_with_offset
    GROUP BY cohort_month, month_offset
)

SELECT
    cs.cohort_month                                        AS "cohort_month",
    ROUND(COALESCE(ch0.users_w_purchase,0) * 100.0 / cs.users_in_cohort, 2)  AS "pct_month_1",
    ROUND(COALESCE(ch1.users_w_purchase,0) * 100.0 / cs.users_in_cohort, 2)  AS "pct_month_2",
    ROUND(COALESCE(ch2.users_w_purchase,0) * 100.0 / cs.users_in_cohort, 2)  AS "pct_month_3",
    ROUND(COALESCE(ch3.users_w_purchase,0) * 100.0 / cs.users_in_cohort, 2)  AS "pct_month_4"
FROM cohort_size cs
LEFT JOIN cohort_hits ch0
       ON cs.cohort_month = ch0.cohort_month AND ch0.month_offset = 0
LEFT JOIN cohort_hits ch1
       ON cs.cohort_month = ch1.cohort_month AND ch1.month_offset = 1
LEFT JOIN cohort_hits ch2
       ON cs.cohort_month = ch2.cohort_month AND ch2.month_offset = 2
LEFT JOIN cohort_hits ch3
       ON cs.cohort_month = ch3.cohort_month AND ch3.month_offset = 3
ORDER BY cs.cohort_month;