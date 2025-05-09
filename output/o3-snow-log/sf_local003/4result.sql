/* --------------------------------------------------------------
   RFM SEGMENTATION & AVERAGE SALES-PER-ORDER BY SEGMENT
   --------------------------------------------------------------
   • Recency  (R)  = NTILE(5) rank of MAX(order_purchase_timestamp)
                     1 = most recent, 5 = oldest purchase.
   • Frequency (F) = NTILE(5) rank of COUNT(delivered orders)
                     1 = most orders, 5 = fewest.
   • Monetary  (M) = NTILE(5) rank of SUM(payment_value)
                     1 = highest spend, 5 = lowest.
   • Segment   = classification rules supplied in the brief.
   • Avg-sales-per-order (customer level) = total spend / #orders.
-----------------------------------------------------------------*/
WITH delivered_orders AS (          -- only ‘delivered’ orders
    SELECT  o."order_id",
            o."customer_id",
            c."customer_unique_id",
            CAST(o."order_purchase_timestamp" AS TIMESTAMP) AS "purchase_ts"
    FROM    "E_COMMERCE"."E_COMMERCE"."ORDERS"    o
    JOIN    "E_COMMERCE"."E_COMMERCE"."CUSTOMERS" c
           ON c."customer_id" = o."customer_id"
    WHERE   o."order_status" = 'delivered'
), payments AS (                    -- aggregate payments per order
    SELECT  "order_id",
            SUM("payment_value") AS "order_total"
    FROM    "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS"
    GROUP   BY "order_id"
), customer_metrics AS (            -- raw R, F, M values per customer
    SELECT  d."customer_unique_id",
            COUNT(DISTINCT d."order_id") AS "frequency",
            SUM(p."order_total")         AS "monetary",
            MAX(d."purchase_ts")         AS "latest_purchase_ts"
    FROM    delivered_orders d
    JOIN    payments        p ON p."order_id" = d."order_id"
    GROUP   BY d."customer_unique_id"
), rfm_scored AS (                  -- convert to quintile scores
    SELECT  *,
            NTILE(5) OVER (ORDER BY "latest_purchase_ts" DESC NULLS LAST) AS "R_score",
            NTILE(5) OVER (ORDER BY "frequency"         DESC NULLS LAST) AS "F_score",
            NTILE(5) OVER (ORDER BY "monetary"          DESC NULLS LAST) AS "M_score"
    FROM    customer_metrics
), rfm_segmented AS (               -- apply segment rules & calc avg-sales
    SELECT  *,
            ("F_score" + "M_score") AS "F_plus_M",
            CASE
                WHEN "R_score" = 1 AND "F_plus_M" BETWEEN 1 AND 4                 THEN 'Champions'
                WHEN "R_score" IN (4,5) AND "F_plus_M" BETWEEN 1 AND 2           THEN 'Can''t Lose Them'
                WHEN "R_score" IN (4,5) AND "F_plus_M" BETWEEN 3 AND 6           THEN 'Hibernating'
                WHEN "R_score" IN (4,5) AND "F_plus_M" BETWEEN 7 AND 10          THEN 'Lost'
                WHEN "R_score" IN (2,3) AND "F_plus_M" BETWEEN 1 AND 4           THEN 'Loyal Customers'
                WHEN "R_score"  = 3   AND "F_plus_M" BETWEEN 5 AND 6             THEN 'Needs Attention'
                WHEN "R_score"  = 1   AND "F_plus_M" BETWEEN 7 AND 8             THEN 'Recent Users'
                WHEN ("R_score" = 1 AND "F_plus_M" BETWEEN 5 AND 6)
                     OR ("R_score" = 2 AND "F_plus_M" BETWEEN 5 AND 8)           THEN 'Potential Loyalists'
                WHEN "R_score"  = 1   AND "F_plus_M" BETWEEN 9 AND 10            THEN 'Price Sensitive'
                WHEN "R_score"  = 2   AND "F_plus_M" BETWEEN 9 AND 10            THEN 'Promising'
                WHEN "R_score"  = 3   AND "F_plus_M" BETWEEN 7 AND 10            THEN 'About to Sleep'
                ELSE 'Other'
            END                                                        AS "RFM_segment",
            ROUND("monetary" / NULLIF("frequency",0), 2)               AS "avg_sales_per_order"
    FROM    rfm_scored
)
SELECT  "RFM_segment",
        ROUND(AVG("avg_sales_per_order"), 2) AS "segment_avg_sales_per_order",
        COUNT(DISTINCT "customer_unique_id") AS "customers_in_segment"
FROM    rfm_segmented
GROUP   BY "RFM_segment"
ORDER   BY "segment_avg_sales_per_order" DESC NULLS LAST;