WITH month_totals AS (
    SELECT 
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))  AS "month_start",
        SUM("amount")                                      AS "month_total"
    FROM 
        "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY 
        "customer_id", 
        "month_start"
),

month_diffs AS (
    SELECT
        "customer_id",
        ABS("month_total" 
            - LAG("month_total") OVER (
                PARTITION BY "customer_id" 
                ORDER BY "month_start"
              )
        ) AS "diff"
    FROM 
        month_totals
),

avg_diffs AS (
    SELECT
        "customer_id",
        AVG("diff") AS "avg_monthly_change"
    FROM 
        month_diffs
    WHERE 
        "diff" IS NOT NULL          -- exclude first month (no previous month)
    GROUP BY 
        "customer_id"
),

top_customer AS (
    SELECT
        "customer_id"
    FROM 
        avg_diffs
    ORDER BY 
        "avg_monthly_change" DESC NULLS LAST
    LIMIT 1
)

SELECT 
    CONCAT(c."first_name", ' ', c."last_name") AS "customer_full_name"
FROM 
    top_customer        tc
JOIN 
    "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER" c
      ON tc."customer_id" = c."customer_id";