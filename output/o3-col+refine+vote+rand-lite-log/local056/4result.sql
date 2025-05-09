WITH monthly_totals AS (
    SELECT
        "customer_id",
        strftime('%Y-%m', "payment_date") AS "yr_month",
        SUM("amount")                     AS "month_total"
    FROM "payment"
    GROUP BY "customer_id", "yr_month"
),
month_changes AS (
    SELECT
        "customer_id",
        ABS("month_total" - LAG("month_total") OVER (
                PARTITION BY "customer_id" ORDER BY "yr_month"
        )) AS "month_diff"
    FROM monthly_totals
),
avg_changes AS (
    SELECT
        "customer_id",
        AVG("month_diff") AS "avg_month_change"
    FROM month_changes
    WHERE "month_diff" IS NOT NULL
    GROUP BY "customer_id"
    ORDER BY "avg_month_change" DESC
    LIMIT 1
)
SELECT
    ("c"."first_name" || ' ' || "c"."last_name") AS "full_name"
FROM avg_changes AS a
JOIN "customer" AS c
  ON c."customer_id" = a."customer_id";