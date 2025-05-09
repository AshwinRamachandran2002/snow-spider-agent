WITH preferred_payment_methods AS (
    SELECT
        p."product_category_name",
        op."payment_type",
        COUNT(DISTINCT oi."order_id") AS "order_count",
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(DISTINCT oi."order_id") DESC NULLS LAST
        ) AS rn
    FROM
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" AS oi
    JOIN
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS" AS p
        ON oi."product_id" = p."product_id"
    JOIN
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" AS op
        ON oi."order_id" = op."order_id"
    GROUP BY
        p."product_category_name",
        op."payment_type"
),
most_preferred_payment_methods AS (
    SELECT
        "product_category_name",
        "payment_type"
    FROM
        preferred_payment_methods
    WHERE
        rn = 1
),
total_installments_per_order AS (
    SELECT
        "order_id",
        SUM("payment_installments") AS "total_installments"
    FROM
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS"
    GROUP BY
        "order_id"
),
category_orders AS (
    SELECT DISTINCT
        oi."order_id",
        p."product_category_name",
        op."payment_type"
    FROM
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS" AS oi
    JOIN
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_PRODUCTS" AS p
        ON oi."product_id" = p."product_id"
    JOIN
        BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_PAYMENTS" AS op
        ON oi."order_id" = op."order_id"
    JOIN
        most_preferred_payment_methods AS mppm
        ON p."product_category_name" = mppm."product_category_name"
        AND op."payment_type" = mppm."payment_type"
),
category_order_installments AS (
    SELECT
        co."product_category_name",
        co."payment_type",
        ti."total_installments"
    FROM
        category_orders AS co
    JOIN
        total_installments_per_order AS ti
        ON co."order_id" = ti."order_id"
)
SELECT
    coi."product_category_name" AS "Product_Category_Name",
    coi."payment_type" AS "Payment_Method",
    ROUND(AVG(coi."total_installments"), 4) AS "Average_Total_Payment_Count"
FROM
    category_order_installments AS coi
GROUP BY
    coi."product_category_name",
    coi."payment_type"
ORDER BY
    coi."product_category_name" ASC NULLS LAST;