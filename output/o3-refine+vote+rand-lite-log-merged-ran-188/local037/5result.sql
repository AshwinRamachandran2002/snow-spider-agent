WITH category_payments AS (
    SELECT
        pt.product_category_name_english      AS category_en,
        op.payment_type,
        COUNT(*)                              AS n_payments,
        RANK() OVER (PARTITION BY pt.product_category_name_english
                     ORDER BY COUNT(*) DESC)  AS rnk
    FROM olist_order_payments              AS op
    JOIN olist_order_items                 AS oi  ON oi.order_id = op.order_id
    JOIN olist_products                    AS p   ON p.product_id = oi.product_id
    JOIN product_category_name_translation AS pt  ON pt.product_category_name = p.product_category_name
    GROUP BY
        pt.product_category_name_english,
        op.payment_type
),
dominant_per_category AS (
    SELECT
        category_en,
        payment_type        AS dominant_payment_type,
        n_payments
    FROM category_payments
    WHERE rnk = 1          -- keep only the most-used payment type per category
)
SELECT
    category_en            AS top_category,
    dominant_payment_type,
    n_payments
FROM dominant_per_category
ORDER BY n_payments DESC
LIMIT 3;