WITH category_orders AS (
    /* one row per order and product category */
    SELECT DISTINCT
           oi.order_id,
           p.product_category_name
    FROM olist_order_items AS oi
    JOIN olist_products     AS p ON p.product_id = oi.product_id
    WHERE p.product_category_name IS NOT NULL
),
category_payment_counts AS (
    /* count payments (rows in olist_order_payments) per category & payment type */
    SELECT
           co.product_category_name        AS category,
           op.payment_type,
           COUNT(*)                        AS payment_count
    FROM category_orders        AS co
    JOIN olist_order_payments   AS op ON op.order_id = co.order_id
    GROUP BY
           co.product_category_name,
           op.payment_type
),
ranked AS (
    /* keep the most common payment type for each category */
    SELECT
           category,
           payment_type,
           payment_count,
           ROW_NUMBER() OVER (PARTITION BY category
                              ORDER BY payment_count DESC, payment_type) AS rn
    FROM category_payment_counts
),
dominant_payment_per_category AS (
    SELECT
           category,
           payment_type,
           payment_count
    FROM ranked
    WHERE rn = 1
)
SELECT
       category                             AS product_category_name,
       payment_count                        AS payments_using_most_common_type
FROM dominant_payment_per_category
ORDER BY
       payments_using_most_common_type DESC,
       product_category_name
LIMIT 3;