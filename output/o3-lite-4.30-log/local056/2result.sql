WITH month_totals AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "payment_date") AS ym,
        SUM("amount") AS month_total
    FROM "payment"
    GROUP BY "customer_id", strftime('%Y-%m', "payment_date")
),
month_changes AS (
    SELECT
        "customer_id",
        ABS(month_total - LAG(month_total) OVER (PARTITION BY "customer_id"
                                                 ORDER BY ym)) AS chg
    FROM month_totals
),
avg_change AS (
    SELECT
        "customer_id",
        AVG(chg) AS avg_monthly_change
    FROM month_changes
    WHERE chg IS NOT NULL
    GROUP BY "customer_id"
),
top_customer AS (
    SELECT "customer_id"
    FROM avg_change
    ORDER BY avg_monthly_change DESC
    LIMIT 1
)
SELECT
    c."first_name" || ' ' || c."last_name" AS customer_full_name
FROM "customer" c
JOIN top_customer t ON c."customer_id" = t."customer_id";