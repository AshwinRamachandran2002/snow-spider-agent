/* --------------------------------------------------------------
   Average sales per order across distinct RFM segments
   – delivered orders only
   – Recency = (max purchase date in all delivered orders) 
               − (customer’s most recent delivered purchase date)
   – R, F, M scoring
       R : 1 ≤ 30 days | 2 ≤ 90 days | 3  > 90 days
       F : 1 ≥ 5 orders| 2 ≥ 2 orders| 3  = 1 order
       M : 1 ≥ 500 BRL | 2 ≥ 150 BRL | 3 < 150 BRL
-------------------------------------------------------------- */
WITH ref AS (    -- global anchor date for Recency
    SELECT MAX(julianday("order_purchase_timestamp")) AS max_day
    FROM   "orders"
    WHERE  "order_status" = 'delivered'
),
customer_base AS (   -- basic R, F, M metrics per customer_unique_id
    SELECT  cu."customer_unique_id",
            COUNT(DISTINCT o."order_id")                                  AS freq_orders,
            SUM(op."payment_value")                                       AS monetary_total,
            ROUND(ref.max_day - MAX(julianday(o."order_purchase_timestamp")),1) AS recency_days
    FROM    "orders"         AS o
    JOIN    ref
    JOIN    "customers"      AS cu ON cu."customer_id" = o."customer_id"
    JOIN    "order_payments" AS op ON op."order_id"    = o."order_id"
    WHERE   o."order_status" = 'delivered'
    GROUP BY cu."customer_unique_id"
),
scored AS (          -- assign the three scores and customer-level AOV
    SELECT  customer_unique_id,
            freq_orders,
            monetary_total,
            recency_days,
            ROUND(monetary_total * 1.0 / freq_orders, 2)                 AS avg_sales_per_order,
            CASE WHEN recency_days <= 30  THEN 1
                 WHEN recency_days <= 90  THEN 2 ELSE 3 END              AS R_score,
            CASE WHEN freq_orders  >= 5  THEN 1
                 WHEN freq_orders  >= 2  THEN 2 ELSE 3 END              AS F_score,
            CASE WHEN monetary_total >= 500 THEN 1
                 WHEN monetary_total >= 150 THEN 2 ELSE 3 END           AS M_score
    FROM    customer_base
),
segment_agg AS (     -- segment-level comparison of average order values
    SELECT  printf('%d%d%d', R_score, F_score, M_score)                  AS RFM_segment_code,
            ROUND(SUM(monetary_total) * 1.0 / SUM(freq_orders), 2)       AS avg_sales_per_order,
            COUNT(*)                                                     AS customers_in_segment
    FROM    scored
    GROUP BY RFM_segment_code
)
SELECT *
FROM   segment_agg
ORDER  BY avg_sales_per_order DESC;