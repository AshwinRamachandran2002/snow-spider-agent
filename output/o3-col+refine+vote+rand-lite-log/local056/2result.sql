WITH monthly_totals AS (
    SELECT
        p."customer_id",
        strftime('%Y-%m', p."payment_date") AS "year_month",
        SUM(p."amount")                     AS "monthly_total"
    FROM "payment" AS p
    GROUP BY p."customer_id", "year_month"
),
monthly_changes AS (
    SELECT
        mt."customer_id",
        mt."year_month",
        mt."monthly_total",
        mt."monthly_total" -
        LAG(mt."monthly_total") OVER (PARTITION BY mt."customer_id"
                                      ORDER BY mt."year_month")      AS "monthly_change"
    FROM monthly_totals AS mt
),
avg_change AS (
    SELECT
        "customer_id",
        AVG(ABS("monthly_change")) AS "avg_monthly_change"
    FROM monthly_changes
    WHERE "monthly_change" IS NOT NULL
    GROUP BY "customer_id"
),
top_customer AS (
    SELECT "customer_id"
    FROM   avg_change
    ORDER  BY "avg_monthly_change" DESC
    LIMIT 1
)
SELECT c."first_name" || ' ' || c."last_name" AS "full_name"
FROM   "customer" AS c
JOIN   top_customer AS t
       ON c."customer_id" = t."customer_id";