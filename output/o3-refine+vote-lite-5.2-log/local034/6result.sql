WITH cat_payments AS (
    SELECT
        p.product_category_name            AS category,
        op.payment_type                    AS payment_type,
        COUNT(*)                           AS num_payments
    FROM "olist_order_items"  oi
    JOIN "olist_products"     p   ON p.product_id = oi.product_id
    JOIN "olist_order_payments" op ON op.order_id = oi.order_id
    GROUP BY
        p.product_category_name,
        op.payment_type
),
preferred_method AS (
    SELECT
        category,
        payment_type,
        num_payments,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY num_payments DESC, payment_type
        ) AS rn
    FROM cat_payments
),
most_preferred AS (
    SELECT
        category,
        num_payments
    FROM preferred_method
    WHERE rn = 1
)
SELECT
    AVG(num_payments * 1.0) AS avg_most_preferred_payment_count
FROM most_preferred;