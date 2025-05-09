WITH category_orders AS (
    /* every (order, category) pair appears only once */
    SELECT DISTINCT
           oi.order_id,
           p.product_category_name AS category
    FROM   olist_order_items  AS oi
    JOIN   olist_products     AS p  ON p.product_id = oi.product_id
    WHERE  p.product_category_name IS NOT NULL
),
payments_per_category AS (
    /* number of payment records per category & payment type */
    SELECT
           co.category,
           op.payment_type,
           COUNT(*) AS payments_count
    FROM   category_orders      AS co
    JOIN   olist_order_payments AS op ON op.order_id = co.order_id
    GROUP BY co.category,
             op.payment_type
),
preferred_method AS (
    /* keep only the payment method with the largest count in each category */
    SELECT
           category,
           payment_type,
           payments_count,
           RANK() OVER (PARTITION BY category
                        ORDER BY payments_count DESC) AS rnk
    FROM   payments_per_category
)
SELECT ROUND(AVG(payments_count), 4) AS average_total_payments_preferred_method
FROM   preferred_method
WHERE  rnk = 1;