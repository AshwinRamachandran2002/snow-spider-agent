/* ---------------------------------------------------------------
   Average sales-per-order by RFM segment (delivered orders only)
   ---------------------------------------------------------------
   • Recency   = days since the most-recent delivered purchase
                 (julianday('now') – julianday(MAX(purchase_ts))).
   • Frequency = number of delivered orders.
   • Monetary  = total spend on delivered orders.
   • Quartiles: NTILE(4) – score 1 is “best” (low R, high F & M).
   • Segment   = concatenation of the three quartile scores (r||f||m).
   • Average-sales-per-order (requested metric) =
                 total_spend / total_number_of_orders.
------------------------------------------------------------------ */
WITH order_values AS (          -- each delivered order: value + date + customer
    SELECT  o."order_id",
            c."customer_unique_id",
            SUM(op."payment_value")               AS order_value,
            o."order_purchase_timestamp"          AS purchase_ts
    FROM    "orders"          AS o
    JOIN    "customers"       AS c   ON o."customer_id" = c."customer_id"
    JOIN    "order_payments"  AS op  USING ("order_id")
    WHERE   o."order_status" = 'delivered'
    GROUP   BY o."order_id", c."customer_unique_id"
),
customer_rfm AS (              -- raw Recency / Frequency / Monetary per customer
    SELECT  customer_unique_id,
            julianday('now') - julianday(MAX(purchase_ts))   AS recency_days,
            COUNT(*)                                        AS frequency_orders,
            SUM(order_value)                                AS monetary_value
    FROM    order_values
    GROUP   BY customer_unique_id
),
scored AS (                    -- quartile scores (1 = best)
    SELECT  *,
            NTILE(4) OVER (ORDER BY recency_days  ASC)   AS r_score,
            NTILE(4) OVER (ORDER BY frequency_orders DESC) AS f_score,
            NTILE(4) OVER (ORDER BY monetary_value   DESC) AS m_score
    FROM    customer_rfm
),
customer_avg AS (              -- average sales-per-order per customer
    SELECT  customer_unique_id,
            (r_score || f_score || m_score)           AS rfm_segment,
            monetary_value * 1.0 / frequency_orders   AS avg_sales_per_order
    FROM    scored
),
segment_summary AS (           -- final comparison across segments
    SELECT  rfm_segment,
            ROUND(AVG(avg_sales_per_order), 2) AS segment_avg_sales_per_order,
            COUNT(*)                           AS num_customers
    FROM    customer_avg
    GROUP   BY rfm_segment
)
SELECT *
FROM   segment_summary
ORDER  BY segment_avg_sales_per_order DESC;