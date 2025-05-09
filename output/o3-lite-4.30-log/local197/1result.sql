WITH top_customers AS (
    SELECT "customer_id"
    FROM "payment"
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC
    LIMIT 10
),
monthly_totals AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "payment_date") AS "month",
        SUM("amount") AS total_amount
    FROM "payment"
    WHERE "customer_id" IN (SELECT "customer_id" FROM top_customers)
    GROUP BY "customer_id", "month"
),
diffs AS (
    SELECT
        "customer_id",
        "month",
        ROUND(ABS(total_amount - LAG(total_amount) OVER (
                 PARTITION BY "customer_id"
                 ORDER BY "month"
        )), 2) AS diff
    FROM monthly_totals
)
SELECT
    "customer_id",
    "month",
    diff AS max_month_over_month_difference
FROM diffs
WHERE diff IS NOT NULL
ORDER BY diff DESC, "customer_id", "month"
LIMIT 1;