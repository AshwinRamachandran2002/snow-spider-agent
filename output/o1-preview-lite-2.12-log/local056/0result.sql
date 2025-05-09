WITH monthly_payments AS (
  SELECT
    "customer_id",
    strftime('%Y-%m', "payment_date") AS "year_month",
    SUM("amount") AS "monthly_total"
  FROM "payment"
  GROUP BY "customer_id", "year_month"
),
monthly_changes AS (
  SELECT
    "customer_id",
    "year_month",
    "monthly_total",
    LAG("monthly_total") OVER (PARTITION BY "customer_id" ORDER BY "year_month") AS "prev_monthly_total"
  FROM monthly_payments
),
monthly_differences AS (
  SELECT
    "customer_id",
    ROUND(("monthly_total" - "prev_monthly_total"), 4) AS "monthly_change"
  FROM monthly_changes
  WHERE "prev_monthly_total" IS NOT NULL
),
average_monthly_changes AS (
  SELECT
    "customer_id",
    ROUND(AVG(ABS("monthly_change")), 4) AS "average_change"
  FROM monthly_differences
  GROUP BY "customer_id"
),
max_average_change AS (
  SELECT
    MAX("average_change") AS "max_avg_change"
  FROM average_monthly_changes
)
SELECT
  "c"."first_name" || ' ' || "c"."last_name" AS "name"
FROM
  average_monthly_changes AS "a"
  JOIN "customer" AS "c" ON "a"."customer_id" = "c"."customer_id"
WHERE
  "a"."average_change" = (SELECT "max_avg_change" FROM max_average_change)
LIMIT 1;