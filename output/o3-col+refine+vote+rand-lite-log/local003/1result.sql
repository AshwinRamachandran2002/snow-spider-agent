/* ------------------------------------------------------------
   RFM ANALYSIS  –  Average Sales per Order by RFM Segment
   ------------------------------------------------------------
   • Recency  = days between the customer’s most recent
                “delivered” purchase and the most recent date
                present in the delivered orders table.
   • Frequency = number of distinct “delivered” orders made
                 by the customer.
   • Monetary  = total amount paid (sum of order_payments)
                 across all of the customer’s delivered orders.
   • R, F and M are each bucketed into terciles
     (NTILE(3) → scores 1-low, 2-mid, 3-high).
   • Segment labels follow the common rules shown below.
   • Average-sales-per-order for every customer =
         Monetary / Frequency.
     We then average those customer-level values
     inside each segment to see the differences.
---------------------------------------------------------------- */
WITH base AS (                -- one row per customer with R/F/M
    SELECT  c.customer_unique_id,
            MAX(o.order_purchase_timestamp)                                      AS last_purchase,
            ROUND(
                julianday( (SELECT MAX(order_purchase_timestamp)
                             FROM orders
                             WHERE order_status = 'delivered') )        -- reference date
              - julianday( MAX(o.order_purchase_timestamp) )            -- last purchase
            )                                                          AS recency_days,
            COUNT(*)                                                   AS frequency_orders,
            SUM(p.payment_value)                                       AS monetary_total
    FROM    orders          AS o
    JOIN    customers       AS c ON o.customer_id = c.customer_id
    JOIN    order_payments  AS p ON o.order_id    = p.order_id
    WHERE   o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
scores AS (                    -- assign R/F/M tercile scores
    SELECT  b.*,
            NTILE(3) OVER (ORDER BY recency_days      ASC) AS r_score, -- recent → 3
            NTILE(3) OVER (ORDER BY frequency_orders DESC) AS f_score, -- many  → 3
            NTILE(3) OVER (ORDER BY monetary_total   DESC) AS m_score  -- high  → 3
    FROM    base b
),
segmented AS (                 -- map scores to human-readable segment
    SELECT  s.*,
            CASE
                 WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champions'
                 WHEN r_score = 3 AND f_score >= 2 AND m_score >= 2 THEN 'Loyal'
                 WHEN r_score = 3 AND f_score = 1                    THEN 'New Customers'
                 WHEN r_score = 2 AND f_score = 3                    THEN 'Potential Loyalist'
                 WHEN r_score = 1 AND f_score = 3                    THEN 'At Risk'
                 ELSE 'Others'
            END                                                     AS rfm_segment,
            ROUND(1.0 * monetary_total / frequency_orders, 2)        AS avg_sale_per_order
    FROM    scores s
)
SELECT   rfm_segment,
         ROUND(AVG(avg_sale_per_order), 2) AS segment_avg_sale_per_order,
         COUNT(*)                         AS customers_in_segment
FROM     segmented
GROUP BY rfm_segment
ORDER BY segment_avg_sale_per_order DESC;