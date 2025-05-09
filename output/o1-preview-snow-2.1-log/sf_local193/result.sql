WITH FirstPaymentDate AS (
    SELECT
        "customer_id",
        MIN(TRY_TO_TIMESTAMP("payment_date")) AS "first_payment_date"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT"
    GROUP BY
        "customer_id"
),
CustomerPayments AS (
    SELECT
        p."customer_id",
        p."amount",
        TRY_TO_TIMESTAMP(p."payment_date") AS "payment_date"
    FROM
        "SQLITE_SAKILA"."SQLITE_SAKILA"."PAYMENT" p
)
SELECT
    ROUND(AVG(total_ltv), 4) AS "Average_LTV",
    CONCAT(ROUND(AVG(percentage_7_days), 4), '%') AS "Percentage_LTV_in_first_7_days",
    CONCAT(ROUND(AVG(percentage_30_days), 4), '%') AS "Percentage_LTV_in_first_30_days"
FROM (
    SELECT
        cp."customer_id",
        SUM(cp."amount") AS total_ltv,
        SUM(
            CASE
                WHEN cp."payment_date" <= DATEADD('second', 7 * 24 * 60 * 60 - 1, fp."first_payment_date")
                THEN cp."amount"
                ELSE 0
            END
        ) / SUM(cp."amount") * 100 AS percentage_7_days,
        SUM(
            CASE
                WHEN cp."payment_date" <= DATEADD('second', 30 * 24 * 60 * 60 - 1, fp."first_payment_date")
                THEN cp."amount"
                ELSE 0
            END
        ) / SUM(cp."amount") * 100 AS percentage_30_days
    FROM
        CustomerPayments cp
        INNER JOIN FirstPaymentDate fp ON cp."customer_id" = fp."customer_id"
    GROUP BY
        cp."customer_id"
    HAVING
        SUM(cp."amount") > 0
) sub;