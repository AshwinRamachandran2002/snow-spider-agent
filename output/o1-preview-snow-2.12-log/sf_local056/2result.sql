WITH monthly_totals AS (
    SELECT 
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("payment_date", 'YYYY-MM-DD HH24:MI:SS.FF')) AS "month",
        SUM("amount") AS "monthly_total"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id", "month"
),
monthly_changes AS (
    SELECT
        "customer_id",
        "month",
        "monthly_total",
        LAG("monthly_total") OVER (PARTITION BY "customer_id" ORDER BY "month") AS "prev_monthly_total",
        ("monthly_total" - LAG("monthly_total") OVER (PARTITION BY "customer_id" ORDER BY "month")) AS "monthly_change"
    FROM monthly_totals
),
avg_monthly_changes AS (
    SELECT
        "customer_id",
        ROUND(AVG(ABS("monthly_change")), 4) AS "avg_monthly_change"
    FROM monthly_changes
    WHERE "monthly_change" IS NOT NULL
    GROUP BY "customer_id"
)
SELECT
    c."first_name" || ' ' || c."last_name" AS "customer_full_name"
FROM SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
JOIN avg_monthly_changes amc ON c."customer_id" = amc."customer_id"
ORDER BY amc."avg_monthly_change" DESC NULLS LAST
LIMIT 1;