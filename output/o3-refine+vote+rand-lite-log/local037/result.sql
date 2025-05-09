WITH category_payments AS (
    /* count how many payment records each payment type has per product category */
    SELECT
        p.product_category_name,
        op.payment_type,
        COUNT(*) AS payment_cnt
    FROM olist_order_items  oi
    JOIN olist_products     p  ON p.product_id = oi.product_id
    JOIN olist_order_payments op ON op.order_id = oi.order_id
    WHERE p.product_category_name IS NOT NULL
    GROUP BY p.product_category_name, op.payment_type
),
ranked AS (
    /* keep, per category, the payment type with the highest number of payments */
    SELECT
        product_category_name,
        payment_type,
        payment_cnt,
        ROW_NUMBER() OVER (
            PARTITION BY product_category_name
            ORDER BY payment_cnt DESC, payment_type
        ) AS rn
    FROM category_payments
),
most_common AS (
    SELECT
        product_category_name,
        payment_type,
        payment_cnt
    FROM ranked
    WHERE rn = 1          -- the most‑used payment type per category
)
SELECT
    product_category_name,
    payment_type,
    payment_cnt AS payments_count
FROM most_common
ORDER BY payment_cnt DESC, product_category_name
LIMIT 3;