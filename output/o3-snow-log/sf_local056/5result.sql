WITH "monthly_totals" AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date")) AS "month_start",
        SUM("amount") AS "month_total"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id", "month_start"
),
"monthly_changes" AS (
    SELECT
        "customer_id",
        "month_start",
        "month_total",
        LAG("month_total") OVER (PARTITION BY "customer_id" ORDER BY "month_start") AS "prev_month_total"
    FROM "monthly_totals"
),
"avg_changes" AS (
    SELECT
        "customer_id",
        AVG("month_total" - "prev_month_total") AS "avg_monthly_change"
    FROM "monthly_changes"
    WHERE "prev_month_total" IS NOT NULL
    GROUP BY "customer_id"
)
SELECT
    c."first_name" || ' ' || c."last_name" AS "full_name"
FROM "avg_changes" a
JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
    ON a."customer_id" = c."customer_id"
ORDER BY a."avg_monthly_change" DESC NULLS LAST
LIMIT 1;