/* ---------------------------------------------------------------------------
   Average Sales-per-Order by RFM Segment
   – Only “delivered” orders are considered
   – Recency is calculated as the number of days between a customer’s last
     delivered purchase and the most-recent delivered purchase in the whole
     database (analysis date)
   – R, F, M scores are assigned by quintiles (1 = best, 5 = worst)
   – RFM segments are classified according to the business rules provided
   – Average sales-per-order = total_spend / total_number_of_orders
---------------------------------------------------------------------------*/
WITH delivered_orders AS (          -- 1. all delivered orders with customer key
    SELECT
        o."order_id",
        o."order_purchase_timestamp"::TIMESTAMP  AS "purchase_ts",
        c."customer_unique_id"
    FROM  E_COMMERCE.E_COMMERCE."ORDERS"    o
    JOIN  E_COMMERCE.E_COMMERCE."CUSTOMERS" c
          ON o."customer_id" = c."customer_id"
    WHERE o."order_status" = 'delivered'
),
order_value AS (                    -- 2. total value paid per order
    SELECT
        op."order_id",
        SUM(op."payment_value")     AS "order_total_value"
    FROM  E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS" op
    GROUP BY op."order_id"
),
cust_metrics AS (                   -- 3. R, F, M raw metrics per customer
    SELECT
        d."customer_unique_id",
        MAX(d."purchase_ts")           AS "last_purchase_ts",
        COUNT(*)                       AS "order_count",
        SUM(ov."order_total_value")    AS "total_spend"
    FROM  delivered_orders d
    JOIN  order_value      ov ON d."order_id" = ov."order_id"
    GROUP BY d."customer_unique_id"
),
ref_date AS (                       -- 4. most-recent delivered purchase overall
    SELECT MAX("last_purchase_ts") AS "analysis_date" FROM cust_metrics
),
scored AS (                         -- 5. assign quintile scores for R, F, M
    SELECT
        cm.*,
        DATEDIFF('day',
                 cm."last_purchase_ts",
                 rd."analysis_date")                                   AS "recency_days",
        NTILE(5) OVER (ORDER BY DATEDIFF('day',
                                         cm."last_purchase_ts",
                                         rd."analysis_date") ASC)      AS "R_score",
        NTILE(5) OVER (ORDER BY cm."order_count" DESC)                 AS "F_score",
        NTILE(5) OVER (ORDER BY cm."total_spend" DESC)                 AS "M_score"
    FROM  cust_metrics cm
    CROSS JOIN ref_date rd
),
segmented AS (                      -- 6. map scores to named RFM segments
    SELECT
        s.*,
        CASE
            WHEN s."R_score" = 1
                 AND (s."F_score" + s."M_score") BETWEEN 1 AND 4 THEN 'Champions'
            WHEN s."R_score" IN (4,5)
                 AND (s."F_score" + s."M_score") BETWEEN 1 AND 2 THEN 'Can''t Lose Them'
            WHEN s."R_score" IN (4,5)
                 AND (s."F_score" + s."M_score") BETWEEN 3 AND 6 THEN 'Hibernating'
            WHEN s."R_score" IN (4,5)
                 AND (s."F_score" + s."M_score") BETWEEN 7 AND 10 THEN 'Lost'
            WHEN s."R_score" IN (2,3)
                 AND (s."F_score" + s."M_score") BETWEEN 1 AND 4 THEN 'Loyal Customers'
            WHEN s."R_score" = 3
                 AND (s."F_score" + s."M_score") BETWEEN 5 AND 6 THEN 'Needs Attention'
            WHEN s."R_score" = 1
                 AND (s."F_score" + s."M_score") BETWEEN 7 AND 8 THEN 'Recent Users'
            WHEN (s."R_score" = 1 AND (s."F_score" + s."M_score") BETWEEN 5 AND 6)
              OR (s."R_score" = 2 AND (s."F_score" + s."M_score") BETWEEN 5 AND 8)
                 THEN 'Potential Loyalists'
            WHEN s."R_score" = 1
                 AND (s."F_score" + s."M_score") BETWEEN 9 AND 10 THEN 'Price Sensitive'
            WHEN s."R_score" = 2
                 AND (s."F_score" + s."M_score") BETWEEN 9 AND 10 THEN 'Promising'
            WHEN s."R_score" = 3
                 AND (s."F_score" + s."M_score") BETWEEN 7 AND 10 THEN 'About to Sleep'
            ELSE 'Other'
        END AS "RFM_segment"
    FROM scored s
)
-- 7.   Average sales-per-order for each segment (differences across segments)
SELECT
    seg."RFM_segment",
    COUNT(*)                                              AS "customers_in_segment",
    SUM(seg."total_spend")                                AS "segment_total_spend",
    SUM(seg."order_count")                                AS "segment_total_orders",
    ROUND(
        SUM(seg."total_spend") / NULLIF(SUM(seg."order_count"), 0), 2
    )                                                     AS "avg_sales_per_order"
FROM  segmented seg
GROUP BY seg."RFM_segment"
ORDER BY "avg_sales_per_order" DESC NULLS LAST;