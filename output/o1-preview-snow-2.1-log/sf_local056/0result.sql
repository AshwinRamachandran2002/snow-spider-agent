WITH monthly_totals AS (
    SELECT
        "customer_id",
        TO_VARCHAR(TO_TIMESTAMP("payment_date"), 'YYYY-MM') AS "year_month",
        SUM("amount") AS "monthly_total"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY
        "customer_id",
        TO_VARCHAR(TO_TIMESTAMP("payment_date"), 'YYYY-MM')
),
monthly_changes AS (
    SELECT
        "customer_id",
        "year_month",
        "monthly_total",
        LAG("monthly_total") OVER (
            PARTITION BY "customer_id"
            ORDER BY "year_month"
        ) AS "prev_month_total",
        ("monthly_total" - LAG("monthly_total") OVER (
            PARTITION BY "customer_id"
            ORDER BY "year_month"
        )) AS "monthly_change"
    FROM
        monthly_totals
),
average_monthly_changes AS (
    SELECT
        "customer_id",
        AVG(ABS("monthly_change")) AS "avg_monthly_change"
    FROM
        monthly_changes
    WHERE
        "prev_month_total" IS NOT NULL
    GROUP BY
        "customer_id"
),
max_customer AS (
    SELECT
        "customer_id",
        "avg_monthly_change"
    FROM
        average_monthly_changes
    ORDER BY
        "avg_monthly_change" DESC NULLS LAST
    LIMIT 1
)
SELECT
    CONCAT("first_name", ' ', "last_name") AS "customer_full_name"
FROM
    max_customer
    INNER JOIN "SQLITE_SAKILA"."SQLITE_SAKILA"."CUSTOMER"
        ON max_customer."customer_id" = "CUSTOMER"."customer_id";