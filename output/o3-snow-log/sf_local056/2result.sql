WITH monthly AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))          AS month_start,
        SUM("amount")                                              AS monthly_total
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY "customer_id", month_start
), diffs AS (
    SELECT
        "customer_id",
        ABS(monthly_total
            - LAG(monthly_total) OVER (PARTITION BY "customer_id" ORDER BY month_start)
        )                                                         AS diff
    FROM monthly
)
SELECT
    c."first_name" || ' ' || c."last_name"                         AS full_name
FROM (
    SELECT
        "customer_id",
        AVG(diff)                                                  AS avg_monthly_change
    FROM diffs
    WHERE diff IS NOT NULL
    GROUP BY "customer_id"
    ORDER BY avg_monthly_change DESC NULLS LAST
    LIMIT 1
) t
JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
  ON c."customer_id" = t."customer_id";