WITH monthly_totals AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "payment_date") AS "year_month",
        SUM("amount") AS "monthly_total"
    FROM "payment"
    GROUP BY "customer_id", "year_month"
),
diffs AS (
    SELECT
        "customer_id",
        "monthly_total" - LAG("monthly_total") OVER (
            PARTITION BY "customer_id"
            ORDER BY "year_month"
        ) AS "diff"
    FROM monthly_totals
)
SELECT c."first_name" || ' ' || c."last_name" AS "full_name"
FROM "customer" AS c
JOIN (
    SELECT "customer_id"
    FROM diffs
    WHERE "diff" IS NOT NULL
    GROUP BY "customer_id"
    ORDER BY AVG(ABS("diff")) DESC
    LIMIT 1
) AS top ON c."customer_id" = top."customer_id";