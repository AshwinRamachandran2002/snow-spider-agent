/*-----------------------------------------------------------
   Average Sales-per-Order by RFM Segment   –  Snowflake SQL
   ----------------------------------------------------------
   • Delivered orders only
   • Recency = days between latest purchase timestamp and CURRENT_DATE()
   • Frequency = number of delivered orders per customer
   • Monetary  = total spend on delivered orders per customer
   • R, F, M scores = quintiles (NTILE(5))
        – R_score  : 1 = most recent   … 5 = least recent
        – F_score  : 1 = most orders   … 5 = fewest orders
        – M_score  : 1 = biggest spend … 5 = lowest spend
   • Segment rules (F_plus_M = F_score + M_score)
        Champions              R=1  & F_plus_M 1-4
        Can’t Lose Them        R=4/5 & F_plus_M 1-2
        Hibernating            R=4/5 & F_plus_M 3-6
        Lost                   R=4/5 & F_plus_M 7-10
        Loyal Customers        R=2/3 & F_plus_M 1-4
        Needs Attention        R=3   & F_plus_M 5-6
        Recent Users           R=1   & F_plus_M 7-8
        Potential Loyalists    (R=1 & F_plus_M 5-6)  OR (R=2 & F_plus_M 5-8)
        Price Sensitive        R=1   & F_plus_M 9-10
        Promising              R=2   & F_plus_M 9-10
        About to Sleep         R=3   & F_plus_M 7-10
-----------------------------------------------------------*/
WITH delivered_orders AS (       -- order-level spend
    SELECT
        o."order_id",
        c."customer_unique_id",
        o."order_purchase_timestamp",
        SUM(p."payment_value") AS "order_value"
    FROM  "E_COMMERCE"."E_COMMERCE"."ORDERS"          o
    JOIN  "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS"  p  ON p."order_id" = o."order_id"
    JOIN  "E_COMMERCE"."E_COMMERCE"."CUSTOMERS"       c  ON c."customer_id" = o."customer_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY o."order_id",
             c."customer_unique_id",
             o."order_purchase_timestamp"
),
customer_rfm AS (              -- raw R / F / M metrics
    SELECT
        "customer_unique_id",
        COUNT(*)                        AS "order_count",            -- F
        SUM("order_value")              AS "total_spend",            -- M
        MAX("order_purchase_timestamp") AS "last_purchase_ts",
        DATEDIFF('day',
                 MAX("order_purchase_timestamp"),
                 CURRENT_DATE())        AS "recency_days"            -- R
    FROM delivered_orders
    GROUP BY "customer_unique_id"
),
scored AS (                     -- 1-5 quintile scores
    SELECT
        r.*,
        NTILE(5) OVER (ORDER BY "recency_days"  ASC)  AS "R_score",
        NTILE(5) OVER (ORDER BY "order_count"   DESC) AS "F_score",
        NTILE(5) OVER (ORDER BY "total_spend"   DESC) AS "M_score"
    FROM customer_rfm r
),
labeled AS (                    -- RFM segment
    SELECT
        s.*,
        ("F_score" + "M_score")                          AS "F_plus_M",
        CASE
            WHEN "R_score" = 1
                 AND "F_score" + "M_score" BETWEEN 1 AND 4              THEN 'Champions'
            WHEN "R_score" IN (4,5)
                 AND "F_score" + "M_score" BETWEEN 1 AND 2              THEN 'Cant_Lose_Them'
            WHEN "R_score" IN (4,5)
                 AND "F_score" + "M_score" BETWEEN 3 AND 6              THEN 'Hibernating'
            WHEN "R_score" IN (4,5)
                 AND "F_score" + "M_score" BETWEEN 7 AND 10             THEN 'Lost'
            WHEN "R_score" IN (2,3)
                 AND "F_score" + "M_score" BETWEEN 1 AND 4              THEN 'Loyal_Customers'
            WHEN "R_score" = 3
                 AND "F_score" + "M_score" BETWEEN 5 AND 6              THEN 'Needs_Attention'
            WHEN "R_score" = 1
                 AND "F_score" + "M_score" BETWEEN 7 AND 8              THEN 'Recent_Users'
            WHEN ( "R_score" = 1
                    AND "F_score" + "M_score" BETWEEN 5 AND 6 )
                 OR ( "R_score" = 2
                    AND "F_score" + "M_score" BETWEEN 5 AND 8 )         THEN 'Potential_Loyalists'
            WHEN "R_score" = 1
                 AND "F_score" + "M_score" BETWEEN 9 AND 10             THEN 'Price_Sensitive'
            WHEN "R_score" = 2
                 AND "F_score" + "M_score" BETWEEN 9 AND 10             THEN 'Promising'
            WHEN "R_score" = 3
                 AND "F_score" + "M_score" BETWEEN 7 AND 10             THEN 'About_to_Sleep'
            ELSE 'Other'
        END AS "rfm_segment"
    FROM scored s
),
customer_avg AS (               -- avg sales per order per customer
    SELECT
        "customer_unique_id",
        "rfm_segment",
        "total_spend",
        "order_count",
        "total_spend" / NULLIF("order_count",0) AS "avg_sales_per_order"
    FROM labeled
)
SELECT
    "rfm_segment",
    AVG("avg_sales_per_order") AS "segment_avg_sales"
FROM customer_avg
GROUP BY "rfm_segment"
ORDER BY "segment_avg_sales" DESC NULLS LAST;