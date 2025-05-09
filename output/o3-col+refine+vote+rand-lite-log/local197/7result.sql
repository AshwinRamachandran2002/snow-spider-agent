WITH top10 AS (
    SELECT "customer_id"
    FROM   "payment"
    GROUP  BY "customer_id"
    ORDER  BY SUM("amount") DESC
    LIMIT 10
),
monthly_totals AS (
    SELECT
        p."customer_id",
        strftime('%Y-%m', p."payment_date")          AS "month",
        SUM(p."amount")                              AS "monthly_paid"
    FROM   "payment" p
    JOIN   top10      USING ("customer_id")
    GROUP  BY p."customer_id", "month"
),
with_diff AS (
    SELECT
        "customer_id",
        "month",
        ABS("monthly_paid" -
            LAG("monthly_paid") OVER (PARTITION BY "customer_id" ORDER BY "month")
        )                                            AS "diff_to_prev"
    FROM   monthly_totals
)
SELECT
    d."customer_id",
    c."first_name" || ' ' || c."last_name"          AS "customer_name",
    d."month"                                       AS "current_month",
    ROUND(d."diff_to_prev", 2)                      AS "largest_monthly_change"
FROM   with_diff d
JOIN   "customer" c ON c."customer_id" = d."customer_id"
WHERE  d."diff_to_prev" IS NOT NULL
ORDER  BY d."diff_to_prev" DESC
LIMIT 1;