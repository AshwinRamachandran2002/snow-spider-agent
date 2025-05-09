WITH monthly_amounts AS (
    SELECT 
        p."customer_id",
        SUBSTRING(p."payment_date", 1, 7) AS "payment_month",
        SUM(p."amount") AS "monthly_amount"
    FROM 
        SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT p
    GROUP BY 
        p."customer_id", "payment_month"
),
monthly_changes AS (
    SELECT
        m."customer_id",
        m."payment_month",
        m."monthly_amount",
        LAG(m."monthly_amount") OVER (PARTITION BY m."customer_id" ORDER BY m."payment_month") AS "previous_month_amount",
        m."monthly_amount" - LAG(m."monthly_amount") OVER (PARTITION BY m."customer_id" ORDER BY m."payment_month") AS "monthly_change"
    FROM
        monthly_amounts m
),
average_changes AS (
    SELECT
        mc."customer_id",
        ROUND(AVG(ABS(mc."monthly_change")), 4) AS "avg_monthly_change"
    FROM
        monthly_changes mc
    WHERE
        mc."monthly_change" IS NOT NULL
    GROUP BY
        mc."customer_id"
)
SELECT
    CONCAT(c."first_name", ' ', c."last_name") AS "customer_full_name"
FROM
    average_changes ac
    JOIN SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER c ON ac."customer_id" = c."customer_id"
ORDER BY
    ac."avg_monthly_change" DESC NULLS LAST, c."customer_id"
LIMIT 1;