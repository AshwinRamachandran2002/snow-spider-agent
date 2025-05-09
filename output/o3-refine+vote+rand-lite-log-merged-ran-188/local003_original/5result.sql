WITH
-- 1) Delivered orders linked to the unique customer id
delivered_orders AS (
    SELECT  o.order_id,
            o.order_purchase_timestamp,
            c.customer_unique_id
    FROM    orders   o
    JOIN    customers c ON c.customer_id = o.customer_id
    WHERE   o.order_status = 'delivered'
),
-- 2) Money actually paid for each delivered order
payments_per_order AS (
    SELECT  order_id,
            SUM(payment_value) AS order_value
    FROM    order_payments
    GROUP BY order_id
),
-- 3) Raw R (last purchase date), F (order count), M (total spend) per customer
customer_rfm AS (
    SELECT  d.customer_unique_id,
            COUNT(DISTINCT d.order_id)            AS frequency,          -- F
            SUM(p.order_value)                    AS monetary,           -- M
            MAX(d.order_purchase_timestamp)       AS last_purchase       -- for R
    FROM    delivered_orders d
    JOIN    payments_per_order p ON p.order_id = d.order_id
    GROUP BY d.customer_unique_id
),
-- 4) Recency (days since last purchase, lower = better)
with_recency AS (
    SELECT  cr.*,
            CAST(julianday( (SELECT MAX(last_purchase) FROM customer_rfm) )
                 - julianday(cr.last_purchase) AS INTEGER) AS recency_days
    FROM    customer_rfm cr
),
-- 5) Quartile‑based R, F, M scores (1‑worst … 4‑best)
recency_scored AS (
    SELECT *,
           (5 - NTILE(4) OVER (ORDER BY recency_days ASC)) AS r_score    -- invert: recent = high score
    FROM   with_recency
),
freq_scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY frequency DESC)         AS f_score    -- more orders = high score
    FROM   recency_scored
),
rfm_scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY monetary DESC)          AS m_score    -- more spend = high score
    FROM   freq_scored
),
-- 6) Customer‑level segment & average sales per order
customer_segment AS (
    SELECT  customer_unique_id,
            r_score,
            f_score,
            m_score,
            (r_score || f_score || m_score)             AS rfm_segment,
            ROUND(monetary * 1.0 / frequency, 4)        AS avg_sales_per_order
    FROM    rfm_scored
)
-- 7) Average sales per order inside each RFM segment
SELECT  rfm_segment,
        ROUND(AVG(avg_sales_per_order), 4) AS avg_sales_per_order
FROM    customer_segment
GROUP BY rfm_segment
ORDER BY rfm_segment;