WITH reference_date_cte AS (
  SELECT MAX(O."order_purchase_timestamp") AS "reference_date"
  FROM "E_COMMERCE"."E_COMMERCE"."ORDERS" O
  WHERE O."order_status" = 'delivered'
),
customer_orders AS (
  SELECT
    O."customer_id",
    O."order_id",
    O."order_purchase_timestamp",
    SUM(OI."price" + OI."freight_value") AS "order_total"
  FROM "E_COMMERCE"."E_COMMERCE"."ORDERS" O
  JOIN "E_COMMERCE"."E_COMMERCE"."ORDER_ITEMS" OI ON O."order_id" = OI."order_id"
  WHERE O."order_status" = 'delivered'
  GROUP BY O."customer_id", O."order_id", O."order_purchase_timestamp"
),
customer_rfm AS (
  SELECT
    "customer_id",
    MAX("order_purchase_timestamp") AS "last_purchase_date",
    COUNT(DISTINCT "order_id") AS "frequency",
    SUM("order_total") AS "monetary"
  FROM customer_orders
  GROUP BY "customer_id"
),
customer_rfm_with_recency AS (
  SELECT
    cr.*,
    DATEDIFF('day', cr."last_purchase_date", rd."reference_date") AS "recency"
  FROM customer_rfm cr
  CROSS JOIN reference_date_cte rd
),
customer_rfm_scores AS (
  SELECT
    crwr.*,
    NTILE(5) OVER (ORDER BY crwr."recency" ASC NULLS LAST) AS "R_score",
    NTILE(5) OVER (ORDER BY crwr."frequency" DESC NULLS LAST) AS "F_score",
    NTILE(5) OVER (ORDER BY crwr."monetary" DESC NULLS LAST) AS "M_score"
  FROM customer_rfm_with_recency crwr
),
customer_segments AS (
  SELECT
    crs."customer_id",
    crs."R_score",
    crs."F_score",
    crs."M_score",
    crs."monetary",
    crs."frequency",
    ROUND(crs."monetary" / crs."frequency", 4) AS "average_sales_per_order",
    CASE
      WHEN crs."R_score" = 5 AND crs."F_score" >= 4 AND crs."M_score" >= 4 THEN 'Champions'
      WHEN crs."R_score" >= 4 AND crs."F_score" >= 3 AND crs."M_score" >= 3 THEN 'Loyal Customers'
      WHEN crs."R_score" >= 3 AND crs."F_score" >= 2 THEN 'Potential Loyalists'
      WHEN crs."R_score" = 5 AND crs."F_score" <= 2 THEN 'Recent Users'
      WHEN crs."R_score" = 4 AND crs."F_score" <= 2 THEN 'Promising'
      WHEN crs."R_score" = 3 AND crs."F_score" <= 2 THEN 'Needs Attention'
      WHEN crs."R_score" = 2 AND crs."F_score" <= 2 THEN 'About to Sleep'
      WHEN crs."R_score" = 1 AND crs."F_score" >= 3 THEN 'Can''t Lose Them'
      WHEN crs."R_score" = 1 AND crs."F_score" <= 2 THEN 'Lost'
      ELSE 'Others'
    END AS "RFM_Segment"
  FROM customer_rfm_scores crs
)
SELECT
  "RFM_Segment",
  ROUND(AVG("average_sales_per_order"), 4) AS "Average_Sales_Per_Order"
FROM customer_segments
GROUP BY "RFM_Segment"
ORDER BY "RFM_Segment" ASC NULLS LAST;