WITH category_payment_counts AS (
    SELECT
        p.product_category_name                       AS category_pt,
        op.payment_type                               AS payment_type,
        COUNT(*)                                      AS payments_count,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_category_name
            ORDER BY COUNT(*) DESC
        )                                             AS rn
    FROM
        olist_order_items        AS oi
        JOIN olist_order_payments AS op ON op.order_id = oi.order_id
        JOIN olist_products       AS p  ON p.product_id = oi.product_id
    GROUP BY
        p.product_category_name,
        op.payment_type
)
SELECT
    COALESCE(t_en.product_category_name_english, cpc.category_pt) AS product_category,
    cpc.payment_type                                               AS most_common_payment_type,
    cpc.payments_count                                             AS payments_count
FROM
    category_payment_counts cpc
    LEFT JOIN product_category_name_translation t_en
           ON t_en.product_category_name = cpc.category_pt
WHERE
    cpc.rn = 1
ORDER BY
    cpc.payments_count DESC,
    product_category ASC
LIMIT 3;