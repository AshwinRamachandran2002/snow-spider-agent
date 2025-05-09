WITH "top10" AS (
    SELECT "customer_id"
    FROM "payment"
    GROUP BY "customer_id"
    ORDER BY SUM("amount") DESC
    LIMIT 10
),
"month_totals" AS (
    SELECT 
        p."customer_id",
        strftime('%Y-%m', p."payment_date")          AS "yyyymm",
        SUM(p."amount")                              AS "month_total"
    FROM   "payment" AS p
    JOIN   "top10"   AS t USING ("customer_id")
    GROUP  BY p."customer_id", "yyyymm"
),
"diffs" AS (
    SELECT
        "customer_id",
        "yyyymm",
        "month_total",
        LAG("month_total") OVER (
            PARTITION BY "customer_id"
            ORDER BY "yyyymm"
        )                                            AS "prev_total"
    FROM   "month_totals"
)
SELECT
    d."customer_id",
    c."first_name" || ' ' || c."last_name"          AS "customer_name",
    d."yyyymm"                                      AS "month_of_change",
    ROUND(ABS(d."month_total" - d."prev_total"),2)  AS "largest_mom_diff"
FROM   "diffs" AS d
JOIN   "customer" AS c USING ("customer_id")
WHERE  d."prev_total" IS NOT NULL
ORDER  BY "largest_mom_diff" DESC
LIMIT 1;