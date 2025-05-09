WITH monthly_totals AS (
    SELECT
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))      AS month_start,
        SUM("amount")                                          AS monthly_amount
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY
        "customer_id",
        DATE_TRUNC('month', TO_TIMESTAMP("payment_date"))
),
monthly_deltas AS (
    SELECT
        "customer_id",
        month_start,
        monthly_amount,
        monthly_amount
          - LAG(monthly_amount) OVER (PARTITION BY "customer_id"
                                      ORDER BY month_start)   AS delta
    FROM
        monthly_totals
),
avg_monthly_change AS (
    SELECT
        "customer_id",
        AVG(ABS(delta))                                        AS avg_change
    FROM
        monthly_deltas
    WHERE
        delta IS NOT NULL
    GROUP BY
        "customer_id"
),
top_customer AS (
    SELECT
        "customer_id"
    FROM
        avg_monthly_change
    ORDER BY
        avg_change DESC NULLS LAST
    LIMIT 1
)
SELECT
    cu."first_name" || ' ' || cu."last_name"                   AS full_name
FROM
    top_customer tc
    JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER" cu
      ON tc."customer_id" = cu."customer_id";