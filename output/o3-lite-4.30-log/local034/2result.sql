WITH category_payment_counts AS (
    SELECT
        p."product_category_name"           AS category,
        pay."payment_type"                  AS pay_type,
        COUNT(*)                            AS n_payments
    FROM "olist_order_payments"  AS pay
    JOIN "olist_order_items"     AS oi  ON oi."order_id"  = pay."order_id"
    JOIN "olist_products"        AS p   ON p."product_id" = oi."product_id"
    GROUP BY p."product_category_name", pay."payment_type"
),
max_per_category AS (
    SELECT
        category,
        MAX(n_payments) AS max_payments
    FROM category_payment_counts
    GROUP BY category
)
SELECT ROUND(AVG(max_payments), 4) AS avg_total_payments
FROM max_per_category;