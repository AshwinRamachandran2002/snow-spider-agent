/* -----------------------------------------------------------
   RFM-based Average Sales per Order by Segment
   -----------------------------------------------------------
   1. Recency  : days since the most recent *delivered* purchase.
                R_score = NTILE(5)   (1 = most recent … 5 = oldest)

   2. Frequency: number of *delivered* orders.
                F_score = NTILE(5)   (1 = most often … 5 = least)

   3. Monetary : total spend on *delivered* orders.
                M_score = NTILE(5)   (1 = highest spend … 5 = lowest)

   4. RFM Segment: assigned with the business rules supplied
      (comparison uses R_score and the sum F_score+M_score).

   5. Average-sales-per-order for every customer =
        total_spend / delivered_orders

   The final result shows how that metric differs across segments.
---------------------------------------------------------------- */

WITH delivered_orders AS (      /* One row = one delivered order  */
    SELECT
        c."customer_unique_id",
        o."order_id",
        SUM(p."payment_value")                        AS "order_value",
        MAX(o."order_purchase_timestamp")             AS "purchase_ts"
    FROM  "E_COMMERCE"."E_COMMERCE"."CUSTOMERS"       c
    JOIN  "E_COMMERCE"."E_COMMERCE"."ORDERS"          o  ON c."customer_id" = o."customer_id"
    JOIN  "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS"  p  ON o."order_id"    = p."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY c."customer_unique_id", o."order_id"
),

customer_agg AS (            /* raw R, F, M values per customer */
    SELECT
        "customer_unique_id",
        COUNT(DISTINCT "order_id")  AS "delivered_orders",
        SUM("order_value")          AS "total_spend",
        MAX("purchase_ts")          AS "last_purchase_ts"
    FROM delivered_orders
    GROUP BY "customer_unique_id"
),

scored AS (                           /* R, F, M scores 1 … 5   */
    SELECT
        ca.*,
        DATEDIFF('day',
                 TO_DATE(ca."last_purchase_ts"),
                 CURRENT_DATE)                         AS "days_since_last_purchase",
        NTILE(5) OVER (ORDER BY
                 DATEDIFF('day',
                          TO_DATE(ca."last_purchase_ts"),
                          CURRENT_DATE) ASC)           AS "R_score",
        NTILE(5) OVER (ORDER BY ca."delivered_orders" DESC) AS "F_score",
        NTILE(5) OVER (ORDER BY ca."total_spend"      DESC) AS "M_score"
    FROM customer_agg ca
),

segmented AS (                    /* business-rule segmentation */
    SELECT
        "customer_unique_id",
        "delivered_orders",
        "total_spend",
        ("total_spend" / NULLIF("delivered_orders",0)) AS "avg_sales_per_order",
        "R_score",
        "F_score",
        "M_score",
        CASE
            WHEN "R_score" = 1 AND ("F_score"+"M_score") BETWEEN 1 AND 4
                 THEN 'Champions'

            WHEN "R_score" IN (4,5) AND ("F_score"+"M_score") BETWEEN 1 AND 2
                 THEN 'Can''t Lose Them'

            WHEN "R_score" IN (4,5) AND ("F_score"+"M_score") BETWEEN 3 AND 6
                 THEN 'Hibernating'

            WHEN "R_score" IN (4,5) AND ("F_score"+"M_score") BETWEEN 7 AND 10
                 THEN 'Lost'

            WHEN "R_score" IN (2,3) AND ("F_score"+"M_score") BETWEEN 1 AND 4
                 THEN 'Loyal Customers'

            WHEN "R_score" = 3 AND ("F_score"+"M_score") BETWEEN 5 AND 6
                 THEN 'Needs Attention'

            WHEN "R_score" = 1 AND ("F_score"+"M_score") BETWEEN 7 AND 8
                 THEN 'Recent Users'

            WHEN ( "R_score" = 1 AND ("F_score"+"M_score") BETWEEN 5 AND 6 )
              OR ( "R_score" = 2 AND ("F_score"+"M_score") BETWEEN 5 AND 8 )
                 THEN 'Potential Loyalists'

            WHEN "R_score" = 1 AND ("F_score"+"M_score") BETWEEN 9 AND 10
                 THEN 'Price Sensitive'

            WHEN "R_score" = 2 AND ("F_score"+"M_score") BETWEEN 9 AND 10
                 THEN 'Promising'

            WHEN "R_score" = 3 AND ("F_score"+"M_score") BETWEEN 7 AND 10
                 THEN 'About to Sleep'

            ELSE 'Other'
        END AS "rfm_segment"
    FROM scored
)

/* ----------  Average sales per order across segments ---------- */
SELECT
    "rfm_segment",
    COUNT(*)                                   AS "customers_in_segment",
    ROUND(AVG("avg_sales_per_order"), 2)       AS "avg_sales_per_order"
FROM segmented
GROUP BY "rfm_segment"
ORDER BY "avg_sales_per_order" DESC NULLS LAST,
         "rfm_segment";