/* -----------------------------------------------------------
   RFM SEGMENTATION & AVERAGE SALES PER ORDER
   -----------------------------------------------------------
   •   RECENCY  = days between each customer’s latest purchase
                  and the most recent purchase observed in the
                  whole delivered-orders data set.
       (Smaller value ⇒ more recent.)

   •   FREQUENCY = total number of delivered orders per customer.

   •   MONETARY  = total spend (sum of payment_value) per customer.

   •   SCORING   = each metric is split into quintiles (1-best … 5-worst
                   for Recency; 1-highest … 5-lowest for Frequency &
                   Monetary) by means of NTILE(5).

   •   SEGMENTS  = customers are mapped to RFM buckets following the
                   logic provided in the task description.

   •   AVERAGE SALES PER ORDER = total_spend / total_orders.
------------------------------------------------------------- */
WITH delivered_orders AS (                -- all delivered orders
    SELECT
        o."order_id",
        c."customer_unique_id",
        o."order_purchase_timestamp"::timestamp AS "purchase_ts"
    FROM E_COMMERCE.E_COMMERCE.ORDERS   o
    JOIN E_COMMERCE.E_COMMERCE.CUSTOMERS c
      ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
), order_values AS (                      -- monetary value per order
    SELECT
        p."order_id",
        SUM(p."payment_value") AS "order_value"
    FROM E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS p
    GROUP BY p."order_id"
), customer_orders AS (                   -- one row per delivered order
    SELECT
        d."customer_unique_id",
        d."order_id",
        d."purchase_ts",
        ov."order_value"
    FROM delivered_orders d
    JOIN order_values     ov ON d."order_id" = ov."order_id"
), customer_agg AS (                      -- R, F, M raw metrics
    SELECT
        co."customer_unique_id",
        MAX(co."purchase_ts")                 AS "last_purchase",
        COUNT(*)                              AS "total_orders",
        SUM(co."order_value")                 AS "total_spend"
    FROM customer_orders co
    GROUP BY co."customer_unique_id"
), recency_base AS (                       -- compute Recency (days)
    SELECT
        ca.*,
        DATEDIFF('day',
                 ca."last_purchase",
                 MAX(ca."last_purchase") OVER()) AS "recency_days"
    FROM customer_agg ca
), rfm_scores AS (                         -- quintile scores 1-5
    SELECT
        rb.*,
        NTILE(5) OVER (ORDER BY rb."recency_days" ASC)  AS "r_score",
        NTILE(5) OVER (ORDER BY rb."total_orders" DESC) AS "f_score",
        NTILE(5) OVER (ORDER BY rb."total_spend"  DESC) AS "m_score"
    FROM recency_base rb
), rfm_segments AS (                       -- map to RFM buckets
    SELECT
        rs.*,
        CASE
            WHEN rs."r_score" = 1
                 AND (rs."f_score" + rs."m_score") BETWEEN 1 AND 4
                 THEN 'Champions'

            WHEN rs."r_score" IN (4,5)
                 AND (rs."f_score" + rs."m_score") BETWEEN 1 AND 2
                 THEN 'Can''t Lose Them'

            WHEN rs."r_score" IN (4,5)
                 AND (rs."f_score" + rs."m_score") BETWEEN 3 AND 6
                 THEN 'Hibernating'

            WHEN rs."r_score" IN (4,5)
                 AND (rs."f_score" + rs."m_score") BETWEEN 7 AND 10
                 THEN 'Lost'

            WHEN rs."r_score" IN (2,3)
                 AND (rs."f_score" + rs."m_score") BETWEEN 1 AND 4
                 THEN 'Loyal Customers'

            WHEN rs."r_score" = 3
                 AND (rs."f_score" + rs."m_score") BETWEEN 5 AND 6
                 THEN 'Needs Attention'

            WHEN rs."r_score" = 1
                 AND (rs."f_score" + rs."m_score") BETWEEN 7 AND 8
                 THEN 'Recent Users'

            WHEN (rs."r_score" = 1
                    AND (rs."f_score" + rs."m_score") BETWEEN 5 AND 6)
              OR (rs."r_score" = 2
                    AND (rs."f_score" + rs."m_score") BETWEEN 5 AND 8)
                 THEN 'Potential Loyalists'

            WHEN rs."r_score" = 1
                 AND (rs."f_score" + rs."m_score") BETWEEN 9 AND 10
                 THEN 'Price Sensitive'

            WHEN rs."r_score" = 2
                 AND (rs."f_score" + rs."m_score") BETWEEN 9 AND 10
                 THEN 'Promising'

            WHEN rs."r_score" = 3
                 AND (rs."f_score" + rs."m_score") BETWEEN 7 AND 10
                 THEN 'About to Sleep'

            ELSE 'Other'
        END AS "rfm_segment"
    FROM rfm_scores rs
)
SELECT
    "rfm_segment",
    AVG("total_spend" / NULLIF("total_orders", 0)) AS "average_sales_per_order"
FROM rfm_segments
GROUP BY "rfm_segment"
ORDER BY "average_sales_per_order" DESC NULLS LAST;