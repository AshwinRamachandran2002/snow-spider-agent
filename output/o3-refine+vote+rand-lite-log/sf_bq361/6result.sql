WITH months_2020 AS (       -- 11 months from Feb‑2020 to Dec‑2020
    SELECT DATE_TRUNC('month', DATEADD('month', seq4(), '2020-02-01')) AS month_start
    FROM TABLE(GENERATOR(ROWCOUNT => 11))
),

/*  All completed purchases (order‑item level is the most reliable place
    where we have an explicit “Complete” status)                       */
order_purchases AS (
    SELECT
        "user_id",
        TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000)) AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" = 'Complete'
),

/*  Users whose very first purchase happened in January‑2020            */
cohort AS (
    SELECT DISTINCT "user_id"
    FROM (
        SELECT
            "user_id",
            MIN(order_date) AS first_purchase_date
        FROM order_purchases
        GROUP BY "user_id"
    )
    WHERE first_purchase_date >= '2020-01-01'
      AND first_purchase_date <  '2020-02-01'
),

/*  Purchases made by those cohort users in the rest of 2020            */
returns_2020 AS (
    SELECT
        DATE_TRUNC('month', op.order_date) AS order_month,
        op."user_id"
    FROM order_purchases op
    JOIN cohort c
      ON c."user_id" = op."user_id"
    WHERE op.order_date >= '2020-02-01'
      AND op.order_date <  '2021-01-01'
),

/*  Number of returning users per month                                 */
monthly_returners AS (
    SELECT
        order_month,
        COUNT(DISTINCT "user_id") AS returning_users
    FROM returns_2020
    GROUP BY order_month
),

/*  Combine calendar months with the actual return counts               */
final AS (
    SELECT
        m.month_start                                               AS month_start,
        COALESCE(r.returning_users, 0)                              AS returning_users
    FROM months_2020          m
    LEFT JOIN monthly_returners r
           ON r.order_month = m.month_start
)

SELECT
    TO_VARCHAR(month_start, 'YYYY-MM')                              AS "month",
    returning_users                                                 AS "returning_users",
    (SELECT COUNT(*) FROM cohort)                                   AS "total_cohort_users",
    ROUND(returning_users / NULLIF((SELECT COUNT(*) FROM cohort),0), 4)
                                                                    AS "proportion_returning"
FROM final
ORDER BY month_start;