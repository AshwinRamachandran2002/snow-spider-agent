WITH category_payment_counts AS (
    SELECT p."product_category_name", op."payment_type", COUNT(*) AS "usage_count"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS" p
        ON oi."product_id" = p."product_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" op
        ON oi."order_id" = op."order_id"
    WHERE p."product_category_name" IS NOT NULL
    GROUP BY p."product_category_name", op."payment_type"
),
category_most_preferred_payment AS (
    SELECT cpc."product_category_name", 
           cpc."payment_type" AS "Payment_Method",
           cpc."usage_count",
           ROW_NUMBER() OVER (
             PARTITION BY cpc."product_category_name" 
             ORDER BY cpc."usage_count" DESC NULLS LAST
           ) AS rn
    FROM category_payment_counts cpc
),
category_most_preferred_payment_method AS (
    SELECT "product_category_name", "Payment_Method"
    FROM category_most_preferred_payment
    WHERE rn = 1
)
SELECT 
    cmpm."product_category_name" AS "Product_Category_Name",
    cmpm."Payment_Method",
    ROUND(AVG(opc."total_payment_count"), 4) AS "Average_Total_Payment_Count"
FROM category_most_preferred_payment_method cmpm
JOIN (
    SELECT 
        oi."order_id", 
        p."product_category_name", 
        op."payment_type", 
        SUM(op."payment_installments") AS "total_payment_count"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" oi
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS" p
        ON oi."product_id" = p."product_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" op
        ON oi."order_id" = op."order_id"
    WHERE p."product_category_name" IS NOT NULL
    GROUP BY oi."order_id", p."product_category_name", op."payment_type"
) opc
    ON cmpm."product_category_name" = opc."product_category_name"
    AND cmpm."Payment_Method" = opc."payment_type"
GROUP BY cmpm."product_category_name", cmpm."Payment_Method"
ORDER BY cmpm."product_category_name" NULLS LAST;