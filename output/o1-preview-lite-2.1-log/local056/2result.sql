WITH "monthly_totals" AS (
  SELECT
    "customer_id",
    strftime('%Y-%m', "payment_date") AS "month",
    SUM("amount") AS "monthly_total"
  FROM "payment"
  GROUP BY "customer_id", "month"
),
"monthly_changes" AS (
  SELECT
    mt1."customer_id",
    mt1."month",
    ROUND(mt1."monthly_total" - IFNULL(mt2."monthly_total", 0), 4) AS "monthly_change"
  FROM "monthly_totals" mt1
  LEFT JOIN "monthly_totals" mt2
    ON mt1."customer_id" = mt2."customer_id"
    AND mt2."month" = strftime('%Y-%m', date(mt1."month" || '-01', '-1 month'))
),
"avg_monthly_changes" AS (
  SELECT
    "customer_id",
    ROUND(AVG("monthly_change"), 4) AS "avg_monthly_change"
  FROM "monthly_changes"
  GROUP BY "customer_id"
)
SELECT
  c."first_name" || ' ' || c."last_name" AS "name"
FROM "customer" c
JOIN "avg_monthly_changes" a
  ON c."customer_id" = a."customer_id"
ORDER BY a."avg_monthly_change" DESC
LIMIT 1;