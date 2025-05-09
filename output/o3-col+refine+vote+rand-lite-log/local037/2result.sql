-- top-3 product categories whose leading payment type has the most payments
WITH category_payment_counts AS (
    SELECT
        p."product_category_name"      AS category,
        op."payment_type"              AS pay_type,
        COUNT(*)                       AS payments_count
    FROM "olist_order_payments"  AS op
    JOIN "olist_order_items"     AS oi ON oi."order_id" = op."order_id"
    JOIN "olist_products"        AS p  ON p."product_id" = oi."product_id"
    GROUP BY category, pay_type
),
category_leading_payment AS (
    SELECT
        category,
        pay_type,
        payments_count,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY payments_count DESC) AS rn
    FROM category_payment_counts
)
SELECT
    category            AS product_category_name,
    pay_type            AS payment_type,
    payments_count
FROM category_leading_payment
WHERE rn = 1
ORDER BY payments_count DESC
LIMIT 3;