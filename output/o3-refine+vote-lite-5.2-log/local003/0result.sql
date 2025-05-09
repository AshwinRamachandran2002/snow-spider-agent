WITH delivered_orders AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c
          ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
order_values AS (
    SELECT
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_total
    FROM order_items oi
    GROUP BY oi.order_id
),
orders_with_value AS (
    SELECT
        d.customer_unique_id,
        d.order_id,
        d.order_purchase_timestamp,
        ov.order_total
    FROM delivered_orders d
    JOIN order_values ov
          ON ov.order_id = d.order_id
),
customer_stats AS (
    SELECT
        customer_unique_id,
        MAX(order_purchase_timestamp)                    AS last_purchase_date,
        COUNT(DISTINCT order_id)                         AS frequency,
        SUM(order_total)                                 AS monetary_total
    FROM orders_with_value
    GROUP BY customer_unique_id
),
max_date AS (
    SELECT MAX(last_purchase_date) AS global_max_date FROM customer_stats
),
rfm AS (
    SELECT
        cs.customer_unique_id,
        CAST(julianday((SELECT global_max_date FROM max_date))
             - julianday(cs.last_purchase_date)          AS INTEGER)       AS recency_days,
        cs.frequency,
        cs.monetary_total,
        ROUND(cs.monetary_total * 1.0 / cs.frequency, 4) AS avg_sale_per_order,
        CASE
            WHEN (julianday((SELECT global_max_date FROM max_date))
                  - julianday(cs.last_purchase_date)) <= 30 THEN 'R1'
            WHEN (julianday((SELECT global_max_date FROM max_date))
                  - julianday(cs.last_purchase_date)) <= 90 THEN 'R2'
            ELSE 'R3'
        END                                             AS R_label,
        CASE
            WHEN cs.frequency >= 5 THEN 'F1'
            WHEN cs.frequency >= 2 THEN 'F2'
            ELSE 'F3'
        END                                             AS F_label,
        CASE
            WHEN cs.monetary_total >= 1000 THEN 'M1'
            WHEN cs.monetary_total >= 200  THEN 'M2'
            ELSE 'M3'
        END                                             AS M_label
    FROM customer_stats cs
)
SELECT
    R_label || F_label || M_label                       AS RFM_segment,
    ROUND(AVG(avg_sale_per_order), 4)                   AS avg_sales_per_order
FROM rfm
GROUP BY RFM_segment
ORDER BY avg_sales_per_order DESC,
         RFM_segment;