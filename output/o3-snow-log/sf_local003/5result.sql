/* -------------------------------------------------------------
   Average sales-per-order for every RFM segment  (only “delivered”)
   • Recency   = days since customer’s latest delivered order
   • Frequency = number of delivered orders
   • Monetary  = total spend on delivered orders
   • R, F, M scores = quintiles created with NTILE(5)
---------------------------------------------------------------- */
WITH delivered AS (                            -- delivered orders
    SELECT
        "order_id",
        "customer_id",
        "order_purchase_timestamp"::TIMESTAMP AS "order_ts"
    FROM E_COMMERCE.E_COMMERCE."ORDERS"
    WHERE "order_status" = 'delivered'
),
cust_orders AS (                               -- link payments + unique id
    SELECT
        cu."customer_unique_id",
        d."order_id",
        d."order_ts",
        SUM(op."payment_value") AS "order_value"
    FROM delivered d
    JOIN E_COMMERCE.E_COMMERCE."ORDER_PAYMENTS" op
          ON op."order_id" = d."order_id"
    JOIN E_COMMERCE.E_COMMERCE."CUSTOMERS" cu
          ON cu."customer_id" = d."customer_id"
    GROUP BY
        cu."customer_unique_id",
        d."order_id",
        d."order_ts"
),
metrics AS (                                   -- raw R / F / M values
    SELECT
        "customer_unique_id",
        DATEDIFF('day', MAX("order_ts")::DATE, CURRENT_DATE()) AS "recency_days",
        COUNT(*)                                               AS "frequency",
        SUM("order_value")                                     AS "monetary",
        AVG("order_value")                                     AS "avg_sales_per_order"
    FROM cust_orders
    GROUP BY "customer_unique_id"
),
scored AS (                                    -- assign quintile scores
    SELECT
        m.*,
        NTILE(5) OVER (ORDER BY m."recency_days" ASC ) AS "R_score",            -- 1 = most recent
        NTILE(5) OVER (ORDER BY m."frequency"     DESC) AS "F_score",            -- 1 = most frequent
        NTILE(5) OVER (ORDER BY m."monetary"      DESC) AS "M_score"             -- 1 = biggest spender
    FROM metrics m
),
segmented AS (                                 -- map scores to RFM segments
    SELECT
        s."customer_unique_id",
        s."avg_sales_per_order",
        CASE
            WHEN s."R_score" = 1 AND (s."F_score" + s."M_score") BETWEEN 1 AND 4  THEN 'Champions'
            WHEN s."R_score" IN (4,5) AND (s."F_score" + s."M_score") BETWEEN 1 AND 2  THEN 'Can''t Lose Them'
            WHEN s."R_score" IN (4,5) AND (s."F_score" + s."M_score") BETWEEN 3 AND 6  THEN 'Hibernating'
            WHEN s."R_score" IN (4,5) AND (s."F_score" + s."M_score") BETWEEN 7 AND 10 THEN 'Lost'
            WHEN s."R_score" IN (2,3) AND (s."F_score" + s."M_score") BETWEEN 1 AND 4  THEN 'Loyal Customers'
            WHEN s."R_score" = 3 AND (s."F_score" + s."M_score") BETWEEN 5 AND 6       THEN 'Needs Attention'
            WHEN s."R_score" = 1 AND (s."F_score" + s."M_score") BETWEEN 7 AND 8       THEN 'Recent Users'
            WHEN (s."R_score" = 1 AND (s."F_score" + s."M_score") BETWEEN 5 AND 6)
              OR (s."R_score" = 2 AND (s."F_score" + s."M_score") BETWEEN 5 AND 8)     THEN 'Potential Loyalists'
            WHEN s."R_score" = 1 AND (s."F_score" + s."M_score") BETWEEN 9 AND 10      THEN 'Price Sensitive'
            WHEN s."R_score" = 2 AND (s."F_score" + s."M_score") BETWEEN 9 AND 10      THEN 'Promising'
            WHEN s."R_score" = 3 AND (s."F_score" + s."M_score") BETWEEN 7 AND 10      THEN 'About to Sleep'
            ELSE 'Other'
        END AS "rfm_segment"
    FROM scored s
)
SELECT
    "rfm_segment"                         AS "RFM_segment",
    ROUND(AVG("avg_sales_per_order"), 2)  AS "avg_sales_per_order"
FROM segmented
GROUP BY "rfm_segment"
ORDER BY "avg_sales_per_order" DESC NULLS LAST;