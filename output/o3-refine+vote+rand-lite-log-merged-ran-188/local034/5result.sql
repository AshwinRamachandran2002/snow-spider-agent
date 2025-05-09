WITH item_category AS (
    -- find every (order, product category) pair
    SELECT DISTINCT oi.order_id,
           p.product_category_name AS category
    FROM olist_order_items      AS oi
    JOIN olist_products         AS p ON p.product_id = oi.product_id
    WHERE p.product_category_name IS NOT NULL
),
payment_by_category AS (
    -- count payments per (category, payment type)
    SELECT ic.category,
           op.payment_type,
           COUNT(*) AS payments_cnt
    FROM item_category          AS ic
    JOIN olist_order_payments   AS op ON op.order_id = ic.order_id
    GROUP BY ic.category,
             op.payment_type
),
most_preferred AS (
    -- pick the payment type with the highest count in each category
    SELECT category,
           payment_type,
           payments_cnt
    FROM (
        SELECT category,
               payment_type,
               payments_cnt,
               ROW_NUMBER() OVER (
                   PARTITION BY category
                   ORDER BY payments_cnt DESC, payment_type
               ) AS rn
        FROM payment_by_category
    )
    WHERE rn = 1
)
-- average of the totals of the most‑preferred payment method in each category
SELECT AVG(payments_cnt) AS avg_payments_of_most_preferred_method
FROM most_preferred;