WITH order_category AS (
    SELECT DISTINCT
           oi.order_id,
           p.product_category_name
    FROM olist_order_items AS oi
    JOIN olist_products   AS p  ON p.product_id = oi.product_id
),
category_payment_counts AS (
    SELECT
        oc.product_category_name  AS category,
        op.payment_type,
        COUNT(*)                  AS num_payments
    FROM order_category       AS oc
    JOIN olist_order_payments AS op ON op.order_id = oc.order_id
    GROUP BY
        oc.product_category_name,
        op.payment_type
),
category_top_payment AS (
    SELECT
        category,
        payment_type,
        num_payments
    FROM (
        SELECT
            category,
            payment_type,
            num_payments,
            ROW_NUMBER() OVER (PARTITION BY category
                               ORDER BY num_payments DESC, payment_type) AS rn
        FROM category_payment_counts
    )
    WHERE rn = 1          -- keep only the most preferred payment method per category
)
SELECT ROUND(AVG(num_payments), 4) AS average_top_payment_count
FROM category_top_payment;