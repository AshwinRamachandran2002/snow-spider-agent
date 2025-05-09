-- 1) find a reference date (most-recent delivered purchase in the base)
WITH reference AS (
     SELECT MAX("order_purchase_timestamp") AS max_date
     FROM   "orders"
     WHERE  "order_status" = 'delivered'
),

-- 2) total paid in each order
order_totals AS (
     SELECT "order_id",
            SUM("payment_value") AS order_total
     FROM   "order_payments"
     GROUP  BY "order_id"
),

-- 3) customer level R, F, M metrics  (only ‘delivered’ orders)
customer_rfm AS (
     SELECT  c."customer_unique_id",
             /* Recency : days since latest purchase */
             julianday( (SELECT max_date FROM reference) )
           - julianday( MAX(o."order_purchase_timestamp") )     AS recency_days,
             /* Frequency */
             COUNT(*)                                           AS frequency,
             /* Monetary */
             SUM(ot.order_total)                                AS monetary_total,
             /* Average sales per order */
             SUM(ot.order_total)*1.0 / COUNT(*)                 AS avg_sales_per_order
     FROM    "orders"        o
     JOIN    "customers"     c  ON c."customer_id" = o."customer_id"
     JOIN    order_totals    ot ON ot."order_id"   = o."order_id"
     WHERE   o."order_status" = 'delivered'
     GROUP   BY c."customer_unique_id"
),

-- 4) derive R, F, M scores via quartiles (4 = best)
scored AS (
     SELECT  *,
             5 - NTILE(4) OVER (ORDER BY recency_days ASC)       AS r_score,   -- most-recent = 4
             5 - NTILE(4) OVER (ORDER BY frequency     DESC)     AS f_score,   -- most-frequent = 4
             5 - NTILE(4) OVER (ORDER BY monetary_total DESC)    AS m_score    -- highest spend = 4
     FROM    customer_rfm
),

-- 5) assemble the classic 3-digit RFM segment label
segments AS (
     SELECT  *,
             CAST(r_score AS TEXT) || CAST(f_score AS TEXT) || CAST(m_score AS TEXT)
             AS rfm_segment
     FROM    scored
)

-- 6) compare average sales per order across the RFM segments
SELECT   rfm_segment,
         COUNT(*)                              AS customers_in_segment,
         ROUND( AVG(avg_sales_per_order), 4 )  AS segment_avg_sales_per_order
FROM     segments
GROUP BY rfm_segment
ORDER BY rfm_segment;