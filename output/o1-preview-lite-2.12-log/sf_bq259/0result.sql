WITH FirstPurchases AS (
    SELECT
        "user_id",
        DATE_TRUNC('MONTH', MIN(TO_TIMESTAMP("created_at" / 1e6))) AS "first_purchase_month"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE
        TO_TIMESTAMP("created_at" / 1e6) <= '2022-12-31'
    GROUP BY
        "user_id"
),
SubsequentPurchases AS (
    SELECT
        o."user_id",
        fp."first_purchase_month",
        DATEDIFF('MONTH', fp."first_purchase_month", DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at" / 1e6))) AS "months_since_first_purchase"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
    INNER JOIN
        FirstPurchases fp ON o."user_id" = fp."user_id"
    WHERE
        TO_TIMESTAMP(o."created_at" / 1e6) <= '2022-12-31'
        AND DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at" / 1e6)) > fp."first_purchase_month"
        AND DATEDIFF('MONTH', fp."first_purchase_month", DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at" / 1e6))) BETWEEN 1 AND 4
)
SELECT
    TO_CHAR(fp."first_purchase_month", 'YYYY-MM') AS "Month_of_First_Purchase",
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN sp."months_since_first_purchase" = 1 THEN sp."user_id" END)
        /
        COUNT(DISTINCT fp."user_id"), 4
    ) AS "Percentage_Repurchase_in_First_Month",
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN sp."months_since_first_purchase" = 2 THEN sp."user_id" END)
        /
        COUNT(DISTINCT fp."user_id"), 4
    ) AS "Percentage_Repurchase_in_Second_Month",
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN sp."months_since_first_purchase" = 3 THEN sp."user_id" END)
        /
        COUNT(DISTINCT fp."user_id"), 4
    ) AS "Percentage_Repurchase_in_Third_Month",
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN sp."months_since_first_purchase" = 4 THEN sp."user_id" END)
        /
        COUNT(DISTINCT fp."user_id"), 4
    ) AS "Percentage_Repurchase_in_Fourth_Month"
FROM
    FirstPurchases fp
LEFT JOIN
    SubsequentPurchases sp ON fp."user_id" = sp."user_id" AND fp."first_purchase_month" = sp."first_purchase_month"
WHERE
    fp."first_purchase_month" <= DATE_TRUNC('MONTH', DATEADD('MONTH', -4, '2022-12-31'))
GROUP BY
    fp."first_purchase_month"
ORDER BY
    fp."first_purchase_month";