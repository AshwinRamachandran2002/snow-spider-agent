WITH delivered_order_sales AS (      -- 1. one row per delivered order
    SELECT
        oi.order_id,
        o.order_purchase_timestamp,
        o.customer_id,
        SUM(oi.price + oi.freight_value) AS order_sales
    FROM orders o
    JOIN order_items oi USING (order_id)
    WHERE o.order_status = 'delivered'
    GROUP BY oi.order_id
),
customer_metrics AS (                -- 2. metrics at customer_unique_id level
    SELECT
        c.customer_unique_id,
        COUNT(*)                       AS frequency,              -- F
        SUM(dos.order_sales)           AS monetary,               -- M
        MAX(dos.order_purchase_timestamp) AS last_purchase_ts     -- for R
    FROM delivered_order_sales dos
    JOIN customers c ON c.customer_id = dos.customer_id
    GROUP BY c.customer_unique_id
),
rfm_base AS (                         -- 3. add Recency in days
    SELECT *,
           CAST(julianday((SELECT MAX(order_purchase_timestamp)
                           FROM delivered_order_sales))
                - julianday(last_purchase_ts) AS INTEGER) AS recency_days
    FROM customer_metrics
),
scored AS (                           -- 4. NTILE(3) scores (1 = best)
    SELECT *,
           NTILE(3) OVER (ORDER BY recency_days  ASC)  AS r_ntile,
           NTILE(3) OVER (ORDER BY frequency     DESC) AS f_ntile,
           NTILE(3) OVER (ORDER BY monetary      DESC) AS m_ntile
    FROM rfm_base
),
labeled AS (                          -- 5. assign segment & customer‑level avg
    SELECT
        customer_unique_id,
        monetary * 1.0 / frequency            AS avg_sales_per_order,
        CASE
            WHEN r_ntile = 1 AND f_ntile = 1 AND m_ntile = 1                THEN 'Champions'
            WHEN r_ntile = 1 AND f_ntile IN (1,2) AND m_ntile IN (1,2)      THEN 'Loyal'
            WHEN r_ntile = 2 AND f_ntile = 1 AND m_ntile = 1                THEN 'Potential Loyalist'
            WHEN r_ntile = 3 AND f_ntile = 3 AND m_ntile = 3                THEN 'Lost'
            ELSE 'Others'
        END AS rfm_segment
    FROM scored
),
segment_stats AS (                    -- 6. segment‑level averages
    SELECT
        rfm_segment,
        AVG(avg_sales_per_order) AS segment_avg
    FROM labeled
    GROUP BY rfm_segment
),
overall AS (                          -- 7. overall customer average
    SELECT AVG(avg_sales_per_order) AS overall_avg
    FROM labeled
)
SELECT
    s.rfm_segment,
    printf('%.4f', s.segment_avg)                         AS average_sales_per_order,
    printf('%.4f', s.segment_avg - o.overall_avg)         AS vs_overall_average
FROM segment_stats s
CROSS JOIN overall o
ORDER BY s.segment_avg DESC;