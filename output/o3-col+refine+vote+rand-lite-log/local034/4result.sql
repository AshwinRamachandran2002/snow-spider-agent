WITH category_payment_counts AS (
    SELECT 
        p.product_category_name,
        op.payment_type,
        COUNT(*) AS payment_count
    FROM olist_order_payments op
    JOIN olist_order_items   oi ON op.order_id = oi.order_id
    JOIN olist_products      p  ON oi.product_id = p.product_id
    GROUP BY 
        p.product_category_name,
        op.payment_type
),
ranked_methods AS (
    SELECT
        product_category_name,
        payment_type,
        payment_count,
        RANK() OVER (
            PARTITION BY product_category_name 
            ORDER BY payment_count DESC
        ) AS payment_rank
    FROM category_payment_counts
)
SELECT 
    ROUND(AVG(payment_count), 4) AS avg_payments_most_preferred
FROM ranked_methods
WHERE payment_rank = 1;