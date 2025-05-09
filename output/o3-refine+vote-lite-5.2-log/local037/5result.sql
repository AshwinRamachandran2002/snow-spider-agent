WITH cat_pay_counts AS (
    /* how many payments of each type occur in each product category */
    SELECT
        pr.product_category_name           AS category,
        pay.payment_type                   AS payment_type,
        COUNT(*)                           AS payment_count
    FROM olist_order_items        AS oi
    JOIN olist_products           AS pr   ON pr.product_id = oi.product_id
    JOIN olist_order_payments     AS pay  ON pay.order_id  = oi.order_id
    GROUP BY pr.product_category_name, pay.payment_type
),
cat_top_payment AS (
    /* keep, per category, the payment type with the greatest count
       (if tied, the alphabetically‑first payment_type is kept) */
    SELECT
        category,
        payment_type,
        payment_count,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY payment_count DESC, payment_type
        ) AS rk
    FROM cat_pay_counts
)
/* final 3 categories whose top payment type has the largest number of payments */
SELECT
    category,
    payment_type,
    payment_count
FROM cat_top_payment
WHERE rk = 1
ORDER BY payment_count DESC, category
LIMIT 3;