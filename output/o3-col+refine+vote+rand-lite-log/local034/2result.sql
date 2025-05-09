SELECT ROUND(AVG("num_payments"), 4) AS "avg_total_payments_of_top_method"
FROM (
    SELECT 
        p."product_category_name",
        op."payment_type",
        COUNT(*) AS "num_payments",
        ROW_NUMBER() OVER (
            PARTITION BY p."product_category_name"
            ORDER BY COUNT(*) DESC
        ) AS "rn"
    FROM "olist_order_items"        AS oi
    JOIN "olist_products"           AS p  ON oi."product_id" = p."product_id"
    JOIN "olist_order_payments"     AS op ON oi."order_id"   = op."order_id"
    GROUP BY 
        p."product_category_name",
        op."payment_type"
) sub
WHERE "rn" = 1;