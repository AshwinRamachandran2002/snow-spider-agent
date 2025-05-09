WITH category_payment_counts AS (
    SELECT  p."product_category_name"      AS category,
            pay."payment_type",
            COUNT(*)                       AS payment_cnt
    FROM    "olist_order_items"      AS oi
    JOIN    "olist_products"         AS p   ON p."product_id" = oi."product_id"
    JOIN    "olist_order_payments"   AS pay ON pay."order_id" = oi."order_id"
    GROUP BY p."product_category_name", pay."payment_type"
),
ranked AS (
    SELECT  category,
            "payment_type",
            payment_cnt,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY payment_cnt DESC) AS rn
    FROM    category_payment_counts
)
SELECT  category            AS "product_category_name",
        "payment_type"      AS "most_used_payment_type",
        payment_cnt         AS "number_of_payments"
FROM    ranked
WHERE   rn = 1
ORDER BY payment_cnt DESC
LIMIT 3;