WITH monthly_totals AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))        AS "month_start",
        SUM("amount")                                            AS "monthly_total"
    FROM SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT
    GROUP BY
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))
),
monthly_changes AS (
    SELECT
        "customer_id",
        ABS("monthly_total" - LAG("monthly_total") OVER (
                PARTITION BY "customer_id"
                ORDER BY "month_start"
        ))                                                      AS "monthly_change"
    FROM monthly_totals
),
average_changes AS (
    SELECT
        "customer_id",
        AVG("monthly_change")                                   AS "avg_monthly_change"
    FROM monthly_changes
    WHERE "monthly_change" IS NOT NULL
    GROUP BY "customer_id"
),
ranked_customers AS (
    SELECT
        "customer_id",
        "avg_monthly_change",
        ROW_NUMBER() OVER (
            ORDER BY "avg_monthly_change" DESC NULLS LAST
        )                                                       AS "rn"
    FROM average_changes
)
SELECT
    c."first_name" || ' ' || c."last_name"                      AS "full_name"
FROM ranked_customers rc
JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c
      ON c."customer_id" = rc."customer_id"
WHERE rc."rn" = 1;