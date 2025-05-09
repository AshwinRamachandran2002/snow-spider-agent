WITH cohort_base AS (          -- each user’s first purchase month (≤ 2022-12-31)
    SELECT
        "user_id",
        MIN(DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000)))
            AS "first_purchase_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" = 'Complete'
      AND TO_TIMESTAMP("created_at" / 1000000) < '2023-01-01'
    GROUP BY "user_id"
),

purchases AS (                 -- purchases in months 0-3 relative to cohort month
    SELECT
        cb."user_id",
        cb."first_purchase_month",
        DATEDIFF(
            'month',
            cb."first_purchase_month",
            DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))
        ) AS "month_number"
    FROM cohort_base cb
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
          ON cb."user_id" = o."user_id"
    WHERE o."status" = 'Complete'
      AND TO_TIMESTAMP(o."created_at" / 1000000) < '2023-01-01'
      AND DATEDIFF(
            'month',
            cb."first_purchase_month",
            DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))
          ) BETWEEN 0 AND 3
    GROUP BY
        cb."user_id",
        cb."first_purchase_month",
        DATEDIFF(
            'month',
            cb."first_purchase_month",
            DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000))
        )
),

numerators AS (                -- users who purchased in each relative month
    SELECT
        "first_purchase_month",
        "month_number",
        COUNT(DISTINCT "user_id") AS "users_purchased"
    FROM purchases
    GROUP BY "first_purchase_month", "month_number"
),

denominators AS (              -- cohort sizes
    SELECT
        "first_purchase_month",
        COUNT(DISTINCT "user_id") AS "cohort_size"
    FROM cohort_base
    GROUP BY "first_purchase_month"
),

percentages AS (               -- % of cohort purchasing in each month
    SELECT
        n."first_purchase_month",
        n."month_number",
        ROUND(n."users_purchased" * 100.0 / d."cohort_size", 4) AS "pct_of_users"
    FROM numerators   n
    JOIN denominators d
      ON n."first_purchase_month" = d."first_purchase_month"
)

SELECT
    "first_purchase_month"                                            AS "cohort_month",
    MAX(CASE WHEN "month_number" = 0 THEN "pct_of_users" END) AS "month0_pct",
    MAX(CASE WHEN "month_number" = 1 THEN "pct_of_users" END) AS "month1_pct",
    MAX(CASE WHEN "month_number" = 2 THEN "pct_of_users" END) AS "month2_pct",
    MAX(CASE WHEN "month_number" = 3 THEN "pct_of_users" END) AS "month3_pct"
FROM percentages
GROUP BY "first_purchase_month"
ORDER BY "cohort_month";