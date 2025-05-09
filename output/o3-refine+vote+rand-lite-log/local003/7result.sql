/* ----------------------------------------------------------
   RFM‑driven Average Sales per Order, by Segment
   ----------------------------------------------------------
   • Recency  = days since the customer’s most recent *delivered*
                purchase.  Calculated as:
                julianday(MaxGlobalPurchaseDate) − julianday(LastCustomerPurchase)

   • Frequency = number of *delivered* orders placed by the customer.

   • Monetary  = total BRL the customer spent on those delivered orders
                 (price + freight_value).

   • Scoring   = quintiles (NTILE(5)) on each metric
                 – R_score : smaller Recency ⇒ higher score
                 – F_score : larger Frequency ⇒ higher score
                 – M_score : larger Monetary  ⇒ higher score

   • Segment   = CASE on the sum R+F+M
                 13‑15 → ‘Champions’
                 10‑12 → ‘Loyal’
                  7‑ 9 → ‘Potential’
                  4‑ 6 → ‘At Risk’
                    ≤3 → ‘Lost’

   • Average‑sales‑per‑order (customer level) = Monetary / Frequency
---------------------------------------------------------- */

WITH delivered_orders AS (               -- only delivered orders
    SELECT  o.order_id,
            o.customer_id,
            o.order_purchase_timestamp
    FROM    orders o
    WHERE   o.order_status = 'delivered'
),
order_values AS (                        -- money spent per order
    SELECT  do.order_id,
            SUM(oi.price + oi.freight_value) AS order_value
    FROM    delivered_orders  do
    JOIN    order_items       oi USING (order_id)
    GROUP BY do.order_id
),
customer_base AS (                       -- basic R, F, M metrics
    SELECT  c.customer_unique_id,
            MAX(do.order_purchase_timestamp)          AS last_order_ts,
            COUNT(DISTINCT do.order_id)               AS frequency,
            SUM(ov.order_value)                       AS monetary
    FROM    delivered_orders do
    JOIN    order_values     ov ON ov.order_id = do.order_id
    JOIN    customers        c  ON c.customer_id = do.customer_id
    GROUP BY c.customer_unique_id
),
ref_date AS ( SELECT MAX(last_order_ts) AS max_date FROM customer_base ),

customer_rfm AS (                        -- add Recency (in days)
    SELECT  cb.*,
            CAST( julianday((SELECT max_date FROM ref_date))
                - julianday(cb.last_order_ts) AS INTEGER ) AS recency_days
    FROM    customer_base cb
),
scored AS (                              -- quintile scores
    SELECT  *,
            NTILE(5) OVER (ORDER BY recency_days ASC)  AS R_score,
            NTILE(5) OVER (ORDER BY frequency    DESC) AS F_score,
            NTILE(5) OVER (ORDER BY monetary     DESC) AS M_score
    FROM    customer_rfm
),
segmented AS (                           -- segment label + avg sales/order
    SELECT  *,
            R_score + F_score + M_score                       AS rfm_total,
            monetary * 1.0 / frequency                       AS avg_sales_per_order,
            CASE
                WHEN R_score + F_score + M_score >= 13 THEN 'Champions'
                WHEN R_score + F_score + M_score >= 10 THEN 'Loyal'
                WHEN R_score + F_score + M_score >=  7 THEN 'Potential'
                WHEN R_score + F_score + M_score >=  4 THEN 'At Risk'
                ELSE                                           'Lost'
            END AS rfm_segment
    FROM    scored
)
SELECT  rfm_segment,
        ROUND(AVG(avg_sales_per_order), 4) AS avg_sales_per_order_across_customers,
        COUNT(DISTINCT customer_unique_id) AS customers_in_segment
FROM    segmented
GROUP BY rfm_segment
ORDER BY avg_sales_per_order_across_customers DESC,
         rfm_segment;