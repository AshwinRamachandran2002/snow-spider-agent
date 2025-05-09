WITH monthly_totals AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date")) AS "month_start",
        SUM("amount") AS "monthly_amount"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id", "month_start"
),
month_over_month AS (
    SELECT
        "customer_id",
        "monthly_amount",
        LAG("monthly_amount") OVER (PARTITION BY "customer_id" ORDER BY "month_start") AS "prev_month_amount"
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        "customer_id",
        AVG(ABS("monthly_amount" - "prev_month_amount")) AS "avg_monthly_change"
    FROM month_over_month
    WHERE "prev_month_amount" IS NOT NULL
    GROUP BY "customer_id"
),
best_customer AS (
    SELECT "customer_id"
    FROM avg_changes
    ORDER BY "avg_monthly_change" DESC NULLS LAST
    LIMIT 1
)
SELECT
    c."first_name" || ' ' || c."last_name" AS "full_name"
FROM best_customer bc
JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
      ON c."customer_id" = bc."customer_id";