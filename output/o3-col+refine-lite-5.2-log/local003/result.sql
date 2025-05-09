/*  ------------------------------------------------------------
    Average sales per order (AOV) by RFM segment
    – only “delivered” orders and customer_unique_id are used
    – Recency = days since the latest delivered purchase
    – Segmentation rules
          Recency :  R1 ≤30d | R2 31‑90d | R3 >90d
          Frequency: F1 ≥5   | F2 2‑4    | F3 =1
          Monetary : M1 ≥150 | M2 50‑149 | M3 <50      (based on AOV)
    – The query returns, for every combined RFM segment:
          • number of customers in the segment
          • average order value inside the segment
    ------------------------------------------------------------ */
WITH delivered AS (
    SELECT  o."order_id",
            c."customer_unique_id",
            DATE(o."order_purchase_timestamp") AS "purchase_date"
    FROM    "orders"    o
    JOIN    "customers" c ON c."customer_id" = o."customer_id"
    WHERE   o."order_status" = 'delivered'
),
last_date AS (                       -- latest delivered purchase in the whole base
    SELECT MAX("purchase_date") AS "max_date"
    FROM   delivered
),
rfm_raw AS (                         -- raw R, F, M per customer_unique_id
    SELECT  d."customer_unique_id",
            ROUND( julianday( (SELECT max_date FROM last_date) ) -
                   julianday( MAX(d."purchase_date") ), 0)        AS "R",
            COUNT(*)                                               AS "F",
            SUM(oi."price" + oi."freight_value")                   AS "M"
    FROM    delivered d
    JOIN    "order_items" oi ON oi."order_id" = d."order_id"
    GROUP   BY d."customer_unique_id"
),
cust_aov AS (                        -- customer‑level average order value
    SELECT  "customer_unique_id",
            "R",
            "F",
            "M",
            ROUND("M" / "F", 2) AS "avg_sales_per_order"
    FROM    rfm_raw
),
segmented AS (                       -- assign R, F & M buckets
    SELECT  "customer_unique_id",
            "avg_sales_per_order",
            CASE WHEN "R" <= 30 THEN 'R1_<=30d'
                 WHEN "R" <= 90 THEN 'R2_31-90d'
                 ELSE                 'R3_>90d'   END  AS "R_seg",
            CASE WHEN "F" >= 5  THEN 'F1_>=5'
                 WHEN "F" >= 2  THEN 'F2_2-4'
                 ELSE                 'F3_1'      END  AS "F_seg",
            CASE WHEN "avg_sales_per_order" >= 150 THEN 'M1_>=150'
                 WHEN "avg_sales_per_order" >= 50  THEN 'M2_50-149'
                 ELSE                                   'M3_<50'  END  AS "M_seg"
    FROM    cust_aov
),
segment_comparison AS (              -- aggregate to see differences across segments
    SELECT  ("R_seg" || "F_seg" || "M_seg")                 AS "RFM_seg",
            COUNT(*)                                        AS "customers_in_segment",
            ROUND(AVG("avg_sales_per_order"), 2)            AS "segment_avg_sales_per_order"
    FROM    segmented
    GROUP  BY "RFM_seg"
)
SELECT *
FROM   segment_comparison
ORDER  BY "segment_avg_sales_per_order" DESC,
          "customers_in_segment"       DESC;