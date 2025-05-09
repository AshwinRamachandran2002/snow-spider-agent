WITH category_order_payments AS (
    /* one record per category–order–payment type */
    SELECT DISTINCT
           p.product_category_name     AS category,
           op.order_id,
           op.payment_type
    FROM   olist_order_items          AS oi
    JOIN   olist_products             AS p  ON p.product_id = oi.product_id
    JOIN   olist_order_payments       AS op ON op.order_id  = oi.order_id
),
payment_counts AS (
    /* how many payments of each type in every category */
    SELECT
           category,
           payment_type,
           COUNT(*) AS cnt
    FROM   category_order_payments
    GROUP  BY category, payment_type
),
preferred_method AS (
    /* keep the payment method with the highest count in each category */
    SELECT
           category,
           cnt,
           RANK() OVER (PARTITION BY category ORDER BY cnt DESC) AS rnk
    FROM   payment_counts
)
SELECT AVG(cnt) AS avg_most_preferred_payment_count
FROM   preferred_method
WHERE  rnk = 1;