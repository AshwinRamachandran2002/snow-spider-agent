WITH ref_date AS (
    SELECT MAX("order_purchase_timestamp") AS "max_date"
    FROM "orders"
    WHERE "order_status" = 'delivered'
),
order_totals AS (
    SELECT o."order_id",
           o."customer_id",
           o."order_purchase_timestamp",
           SUM(oi."price") AS "total_order_value"
    FROM "orders" o
    JOIN "order_items" oi ON o."order_id" = oi."order_id"
    WHERE o."order_status" = 'delivered'
    GROUP BY o."order_id"
),
customer_rfm AS (
   SELECT
       ot."customer_id",
       MAX(ot."order_purchase_timestamp") AS "last_purchase_date",
       COUNT(DISTINCT ot."order_id") AS "frequency",
       SUM(ot."total_order_value") AS "monetary"
   FROM order_totals ot
   GROUP BY ot."customer_id"
),
customer_rfm_recency AS (
   SELECT
       cr."customer_id",
       cr."frequency",
       cr."monetary",
       cr."last_purchase_date",
       CAST((julianday(rd."max_date") - julianday(cr."last_purchase_date")) AS INTEGER) AS "recency"
   FROM customer_rfm cr, ref_date rd
),
recency_ranks AS (
    SELECT
        crr.*,
        NTILE(5) OVER (ORDER BY crr."recency" ASC) AS "R_score",
        NTILE(5) OVER (ORDER BY crr."frequency" DESC) AS "F_score",
        NTILE(5) OVER (ORDER BY crr."monetary" DESC) AS "M_score"
    FROM customer_rfm_recency crr
),
customer_segments AS (
   SELECT
       "customer_id",
       "recency",
       "frequency",
       "monetary",
       "R_score",
       "F_score",
       "M_score",
       CAST("R_score" AS TEXT) || CAST("F_score" AS TEXT) || CAST("M_score" AS TEXT) AS "RFM_Segment",
       "monetary" * 1.0 / "frequency" AS "avg_sales_per_order"
   FROM recency_ranks
)
SELECT
    "RFM_Segment",
    ROUND(AVG("avg_sales_per_order"), 4) AS "Average_Sales_Per_Order"
FROM customer_segments
GROUP BY "RFM_Segment"
ORDER BY "Average_Sales_Per_Order" DESC;