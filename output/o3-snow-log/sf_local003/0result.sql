/*--------------------------------------------------------------------
  Goal :  Compare the average sales-per-order of customers across RFM
          segments (delivered orders only).
--------------------------------------------------------------------*/
WITH delivered_orders AS (        -- 1. all delivered orders
    SELECT  o."order_id",
            o."customer_id",
            o."order_purchase_timestamp"
    FROM    "E_COMMERCE"."E_COMMERCE"."ORDERS" o
    WHERE   o."order_status" = 'delivered'
),  

customer_metrics AS (             -- 2. raw Recency, Frequency, Monetary
    SELECT  c."customer_unique_id",
            MAX(d."order_purchase_timestamp")                    AS "last_purchase_ts",
            COUNT(DISTINCT d."order_id")                         AS "total_orders",
            SUM(op."payment_value")                              AS "total_spent"
    FROM    "E_COMMERCE"."E_COMMERCE"."CUSTOMERS"      c
    JOIN    delivered_orders                                   d  ON d."customer_id" = c."customer_id"
    JOIN    "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS" op ON op."order_id" = d."order_id"
    GROUP BY c."customer_unique_id"
),

r_scores AS (                     -- 3a. Recency quintiles (1 = most recent)
    SELECT  cm."customer_unique_id",
            NTILE(5) OVER (ORDER BY cm."last_purchase_ts" DESC NULLS LAST) AS "R_score"
    FROM    customer_metrics cm
),

f_scores AS (                     -- 3b. Frequency quintiles (1 = most orders)
    SELECT  cm."customer_unique_id",
            NTILE(5) OVER (ORDER BY cm."total_orders" DESC NULLS LAST)      AS "F_score"
    FROM    customer_metrics cm
),

m_scores AS (                     -- 3c. Monetary quintiles (1 = highest spend)
    SELECT  cm."customer_unique_id",
            NTILE(5) OVER (ORDER BY cm."total_spent" DESC NULLS LAST)       AS "M_score"
    FROM    customer_metrics cm
),

rfm AS (                          -- 4. combine scores & derive avg sales/order
    SELECT  cm.*,
            r."R_score",
            f."F_score",
            m."M_score",
            (f."F_score" + m."M_score")                                    AS "fm_sum",
            (cm."total_spent" / NULLIF(cm."total_orders",0))               AS "avg_sales_per_order"
    FROM    customer_metrics cm
    JOIN    r_scores r USING ("customer_unique_id")
    JOIN    f_scores f USING ("customer_unique_id")
    JOIN    m_scores m USING ("customer_unique_id")
),

rfm_segmented AS (                -- 5. apply business rules to label segments
    SELECT  rfm.*,
        CASE
            WHEN "R_score" = 1                               AND "fm_sum" BETWEEN 1  AND 4  THEN 'Champions'
            WHEN "R_score" IN (2,3)                          AND "fm_sum" BETWEEN 1  AND 4  THEN 'Loyal Customers'
            WHEN ("R_score" = 1 AND "fm_sum" BETWEEN 5 AND 6)
              OR ("R_score" = 2 AND "fm_sum" BETWEEN 5 AND 8)                         THEN 'Potential Loyalists'
            WHEN "R_score" = 1                               AND "fm_sum" BETWEEN 7  AND 8  THEN 'Recent Users'
            WHEN "R_score" = 2                               AND "fm_sum" BETWEEN 9  AND 10 THEN 'Promising'
            WHEN "R_score" = 3                               AND "fm_sum" BETWEEN 5  AND 6  THEN 'Needs Attention'
            WHEN "R_score" = 3                               AND "fm_sum" BETWEEN 7  AND 10 THEN 'About to Sleep'
            WHEN "R_score" IN (4,5)                          AND "fm_sum" BETWEEN 1  AND 2  THEN 'Can''t Lose Them'
            WHEN "R_score" IN (4,5)                          AND "fm_sum" BETWEEN 3  AND 6  THEN 'Hibernating'
            WHEN "R_score" = 1                               AND "fm_sum" BETWEEN 9  AND 10 THEN 'Price Sensitive'
            WHEN "R_score" IN (4,5)                          AND "fm_sum" BETWEEN 7  AND 10 THEN 'Lost'
            ELSE 'Other'
        END                                                  AS "rfm_segment"
    FROM   rfm
)

-- 6. average sales per order per segment
SELECT
    "rfm_segment",
    AVG("avg_sales_per_order")   AS "avg_sales_per_order_per_customer",
    COUNT(DISTINCT "customer_unique_id") AS "customers_in_segment"
FROM   rfm_segmented
GROUP  BY "rfm_segment"
ORDER  BY "avg_sales_per_order_per_customer" DESC NULLS LAST;