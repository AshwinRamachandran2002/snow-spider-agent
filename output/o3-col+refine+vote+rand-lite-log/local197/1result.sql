WITH top10 AS (                        -- 1) the ten biggest lifetime spenders
    SELECT "customer_id"
    FROM   "payment"
    GROUP  BY "customer_id"
    ORDER  BY SUM("amount") DESC
    LIMIT 10
),
monthly AS (                           -- 2) their month-level payment totals
    SELECT  p."customer_id",
            strftime('%Y-%m', p."payment_date") AS "yr_mon",
            SUM(p."amount")                     AS "month_total"
    FROM    "payment" p
    JOIN    top10      t USING ("customer_id")
    GROUP   BY p."customer_id", "yr_mon"
),
diffs AS (                             -- 3) month-over-month differences
    SELECT  "customer_id",
            "yr_mon",
            "month_total"
            - LAG("month_total") OVER (PARTITION BY "customer_id" ORDER BY "yr_mon")
            AS "diff"
    FROM    monthly
)
SELECT  d."customer_id",
        c."first_name",
        c."last_name",
        d."yr_mon",                    -- month in which the jump occurred
        ROUND(d."diff", 2) AS "month_over_month_diff"
FROM    diffs     d
JOIN    "customer" c USING ("customer_id")
WHERE   d."diff" IS NOT NULL
ORDER BY ABS(d."diff") DESC            -- 4) largest absolute change
LIMIT 1;