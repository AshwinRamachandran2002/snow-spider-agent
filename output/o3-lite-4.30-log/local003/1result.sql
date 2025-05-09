WITH delivered_orders AS (             -- per‑order totals (only “delivered”)
    SELECT  o.order_id,
            c.customer_unique_id,
            o.order_purchase_timestamp,
            SUM(oi.price + oi.freight_value)          AS order_total
    FROM    orders      AS o
    JOIN    customers   AS c  ON c.customer_id = o.customer_id
    JOIN    order_items AS oi ON oi.order_id   = o.order_id
    WHERE   o.order_status = 'delivered'
    GROUP BY o.order_id
),
customer_base AS (                     -- per‑customer aggregates
    SELECT  customer_unique_id,
            COUNT(*)                                   AS orders_cnt,
            SUM(order_total)                           AS total_spend,
            MAX(order_purchase_timestamp)              AS last_purchase
    FROM    delivered_orders
    GROUP BY customer_unique_id
),
with_recency AS (                      -- Recency (days since last purchase)
    SELECT  *,
            julianday( (SELECT MAX(last_purchase) FROM customer_base) )
          - julianday(last_purchase)                    AS recency_days
    FROM    customer_base
),
with_scores AS (                       -- quartile scores
    SELECT  *,
            NTILE(4) OVER (ORDER BY recency_days ASC)   AS r,        -- 1 = freshest
            NTILE(4) OVER (ORDER BY orders_cnt  DESC)   AS f_raw,    -- 1 = most orders
            NTILE(4) OVER (ORDER BY total_spend DESC)   AS m_raw     -- 1 = highest spend
    FROM    with_recency
),
rfm_customers AS (                     -- final R,F,M (4 = best for F & M)
    SELECT  customer_unique_id,
            total_spend * 1.0 / orders_cnt             AS avg_sales_per_order,
            r                                          AS R,
            5 - f_raw                                  AS F,
            5 - m_raw                                  AS M
    FROM    with_scores
),
rfm_segment AS (                       -- average order value per RFM segment
    SELECT  R || F || M  AS rfm_segment,
            AVG(avg_sales_per_order)    AS average_sales_per_order
    FROM    rfm_customers
    GROUP BY rfm_segment
),
overall AS (
    SELECT AVG(avg_sales_per_order) AS overall_avg
    FROM   rfm_customers
)
SELECT  rfm_segment,
        ROUND(average_sales_per_order, 4)                      AS average_sales_per_order,
        ROUND(average_sales_per_order - overall_avg, 4)        AS vs_overall_average
FROM    rfm_segment, overall
ORDER BY rfm_segment;