WITH delivered_orders AS (                 -- 1. only orders that were actually delivered
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp
    FROM orders o
    WHERE o.order_status = 'delivered'
),

order_values AS (                          -- 2. how much each delivered order is worth
    SELECT
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_value
    FROM order_items oi
    GROUP BY oi.order_id
),

orders_enriched AS (                       -- 3. link order value with the customer_unique_id
    SELECT
        d.order_id,
        c.customer_unique_id,
        d.order_purchase_timestamp,
        v.order_value
    FROM delivered_orders            AS d
    JOIN customers                  AS c ON c.customer_id = d.customer_id
    JOIN order_values               AS v ON v.order_id     = d.order_id
),

rfm_raw AS (                               -- 4. R,F,M measures for every customer
    SELECT
        customer_unique_id,
        MAX(order_purchase_timestamp)                                AS last_purchase_ts,
        CAST ( julianday( (SELECT MAX(order_purchase_timestamp)
                           FROM delivered_orders) )          -- “today”
             - julianday( MAX(order_purchase_timestamp) ) AS INTEGER) AS recency_days,
        COUNT(order_id)                                             AS frequency,
        SUM(order_value)                                            AS monetary
    FROM orders_enriched
    GROUP BY customer_unique_id
),

rfm_scored AS (                            -- 5. translate the raw numbers into 4‑quantile scores
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        ntile(4) OVER (ORDER BY recency_days ASC)  AS recency_score,     -- lower days → higher score
        ntile(4) OVER (ORDER BY frequency DESC)    AS frequency_score,
        ntile(4) OVER (ORDER BY monetary  DESC)    AS monetary_score
    FROM rfm_raw
),

rfm_segmented AS (                         -- 6. put every customer in an RFM segment
    SELECT
        customer_unique_id,
        monetary * 1.0 / frequency                    AS avg_sales_per_order,
        CASE
            WHEN recency_score = 4 AND frequency_score = 4 AND monetary_score = 4
                 THEN 'champions'
            WHEN recency_score >= 3 AND frequency_score >= 3
                 THEN 'loyal_customers'
            WHEN recency_score >= 3 AND frequency_score <= 2
                 THEN 'potential_loyalists'
            WHEN recency_score = 2 AND frequency_score >= 2
                 THEN 'need_attention'
            ELSE 'at_risk'
        END                                           AS rfm_segment
    FROM rfm_scored
),

segment_comparison AS (                    -- 7. average sales / order inside each segment
    SELECT
        rfm_segment,
        ROUND(AVG(avg_sales_per_order),4) AS average_sales_per_order
    FROM rfm_segmented
    GROUP BY rfm_segment
)

SELECT
    rfm_segment,
    average_sales_per_order
FROM segment_comparison
ORDER BY average_sales_per_order DESC, rfm_segment;