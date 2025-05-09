WITH category_payment_counts AS (
    /* how many payment rows each payment_type contributes to every product category */
    SELECT
        p.product_category_name                           AS category,
        op.payment_type,
        COUNT(DISTINCT op.order_id || '-' || op.payment_sequential) AS payment_count
    FROM olist_order_items        AS oi
    JOIN olist_products           AS p  ON p.product_id = oi.product_id
    JOIN olist_order_payments     AS op ON op.order_id   = oi.order_id
    GROUP BY
        category,
        op.payment_type
),
most_common_payment AS (
    /* pick, for every category, the payment type that occurs the most */
    SELECT
        category,
        payment_type,
        payment_count,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY payment_count DESC, payment_type ASC
        ) AS rn
    FROM category_payment_counts
),
category_top_payment AS (
    /* keep only the most‑common payment type per category */
    SELECT
        category,
        payment_type,
        payment_count
    FROM most_common_payment
    WHERE rn = 1
)
SELECT
    category                     AS product_category_name,
    payment_type                 AS most_common_payment_type,
    payment_count                AS payments_using_that_type
FROM category_top_payment
ORDER BY
    payment_count DESC,
    category ASC
LIMIT 3;