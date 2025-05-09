WITH cat_orders AS (
    /* each category – order combination only once */
    SELECT DISTINCT p.product_category_name   AS category,
                    oi.order_id
    FROM   olist_order_items  AS oi
    JOIN   olist_products     AS p
           ON p.product_id = oi.product_id
),
cat_pay_counts AS (
    /* how many payments of every type were made for each category */
    SELECT  co.category,
            op.payment_type,
            COUNT(*)                 AS payment_count
    FROM    cat_orders          AS co
    JOIN    olist_order_payments AS op
           ON op.order_id = co.order_id
    GROUP BY co.category,
             op.payment_type
),
cat_pref AS (
    /* keep only the count for the most‑used payment type in each category */
    SELECT  category,
            MAX(payment_count)   AS preferred_payment_count
    FROM    cat_pay_counts
    GROUP BY category
)
SELECT AVG(preferred_payment_count * 1.0)  AS avg_preferred_payment_count
FROM   cat_pref;