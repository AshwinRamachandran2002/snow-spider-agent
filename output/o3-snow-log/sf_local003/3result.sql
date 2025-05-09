/*==============================================================================
 RFM-based Average Sales per Order – Segment-level Comparison
 -------------------------------------------------------------------------------
 – Recency  : DAYS since a customer’s last “delivered” order, measured against  
              the most-recent purchase date in the whole data-set.  
 – Frequency: # “delivered” orders per customer.  
 – Monetary : Total spend across those delivered orders.

 Quintile scores (1 = best, 5 = worst) are assigned independently to R, F and M
 via NTILE(5).  The RFM segment labels follow the rules given in the brief.
 The query returns, for every RFM segment:
      • segment-level average of the customer-level “avg sales per order”
      • min / max of that metric among the segment’s customers
      • number of customers in the segment
==============================================================================*/
WITH delivered_orders AS (          -- all delivered orders with their dates
    SELECT
        o."order_id",
        o."customer_id",
        o."order_purchase_timestamp"
    FROM  E_COMMERCE.E_COMMERCE.ORDERS o
    WHERE o."order_status" = 'delivered'
),
order_values AS (                   -- total spend per order
    SELECT
        op."order_id",
        SUM(op."payment_value") AS "order_total_value"
    FROM  E_COMMERCE.E_COMMERCE.ORDER_PAYMENTS op
    GROUP BY op."order_id"
),
rfm_raw AS (                        -- raw R, F, M per customer
    SELECT
        c."customer_unique_id",
        MAX(d."order_purchase_timestamp")             AS "last_purchase_ts",
        COUNT(*)                                      AS "frequency_orders",
        SUM(ov."order_total_value")                   AS "monetary_total"
    FROM  delivered_orders d
    JOIN  order_values             ov  ON d."order_id"  = ov."order_id"
    JOIN  E_COMMERCE.E_COMMERCE.CUSTOMERS c ON d."customer_id" = c."customer_id"
    GROUP BY c."customer_unique_id"
),
scored AS (                        -- attach global latest purchase time
    SELECT
        r.*,
        MAX("last_purchase_ts") OVER () AS "global_last_ts"
    FROM  rfm_raw r
),
quintiled AS (                      -- R, F, M quintile scores
    SELECT
        "customer_unique_id",
        "frequency_orders",
        "monetary_total",
        DATEDIFF('day', "last_purchase_ts", "global_last_ts")                    AS "recency_days",
        NTILE(5) OVER (ORDER BY DATEDIFF('day', "last_purchase_ts", "global_last_ts") ASC)  AS "R_score",
        NTILE(5) OVER (ORDER BY "frequency_orders" DESC)                                     AS "F_score",
        NTILE(5) OVER (ORDER BY "monetary_total"  DESC)                                     AS "M_score"
    FROM scored
),
labeled AS (                        -- map to business-friendly RFM segments
    SELECT
        q.*,
        CASE
            WHEN "R_score" = 1 AND ("F_score" + "M_score") BETWEEN 1  AND 4  THEN 'Champions'
            WHEN "R_score" IN (4,5) AND ("F_score" + "M_score") BETWEEN 1  AND 2  THEN 'Can''t Lose Them'
            WHEN "R_score" IN (4,5) AND ("F_score" + "M_score") BETWEEN 3  AND 6  THEN 'Hibernating'
            WHEN "R_score" IN (4,5) AND ("F_score" + "M_score") BETWEEN 7  AND 10 THEN 'Lost'
            WHEN "R_score" IN (2,3) AND ("F_score" + "M_score") BETWEEN 1  AND 4  THEN 'Loyal Customers'
            WHEN "R_score" = 3       AND ("F_score" + "M_score") BETWEEN 5  AND 6  THEN 'Needs Attention'
            WHEN "R_score" = 1       AND ("F_score" + "M_score") BETWEEN 7  AND 8  THEN 'Recent Users'
            WHEN ( ("R_score" = 1 AND ("F_score" + "M_score") BETWEEN 5 AND 6)
                OR ("R_score" = 2 AND ("F_score" + "M_score") BETWEEN 5 AND 8) )   THEN 'Potential Loyalists'
            WHEN "R_score" = 1       AND ("F_score" + "M_score") BETWEEN 9  AND 10 THEN 'Price Sensitive'
            WHEN "R_score" = 2       AND ("F_score" + "M_score") BETWEEN 9  AND 10 THEN 'Promising'
            WHEN "R_score" = 3       AND ("F_score" + "M_score") BETWEEN 7  AND 10 THEN 'About to Sleep'
            ELSE 'Others'
        END AS "RFM_Segment"
    FROM quintiled q
),
customer_avg AS (                   -- average sales per order *per customer*
    SELECT
        "customer_unique_id",
        "RFM_Segment",
        "monetary_total",
        "frequency_orders",
        ROUND("monetary_total" / NULLIF("frequency_orders",0), 2) AS "avg_sales_per_order"
    FROM labeled
),
segment_comparison AS (             -- compare segments
    SELECT
        "RFM_Segment",
        ROUND(AVG("avg_sales_per_order"), 2) AS "segment_avg_sales_per_order",
        ROUND(MIN("avg_sales_per_order"), 2) AS "min_customer_avg_sales",
        ROUND(MAX("avg_sales_per_order"), 2) AS "max_customer_avg_sales",
        COUNT(*)                            AS "customers_in_segment"
    FROM  customer_avg
    GROUP BY "RFM_Segment"
)
SELECT *
FROM   segment_comparison
ORDER  BY "segment_avg_sales_per_order" DESC NULLS LAST;