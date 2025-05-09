WITH max_date AS (
  SELECT MAX("order_purchase_timestamp") AS "max_date"
  FROM "orders"
  WHERE "order_status" = 'delivered'
),
customer_rfm AS (
  SELECT
    o."customer_id",
    -- Calculate Recency
    ROUND(julianday((SELECT "max_date" FROM max_date)) - julianday(MAX(o."order_purchase_timestamp")), 0) AS "Recency",
    -- Calculate Frequency
    COUNT(DISTINCT o."order_id") AS "Frequency",
    -- Calculate Monetary Value
    SUM(oi."price") AS "Monetary"
  FROM "orders" o
  JOIN "order_items" oi ON o."order_id" = oi."order_id"
  WHERE o."order_status" = 'delivered'
  GROUP BY o."customer_id"
),
rfm_scores AS (
  SELECT
    cr."customer_id",
    cr."Recency",
    cr."Frequency",
    cr."Monetary",
    -- Assign Recency Score
    CASE
      WHEN cr."Recency" <= 30 THEN 4
      WHEN cr."Recency" <= 60 THEN 3
      WHEN cr."Recency" <= 90 THEN 2
      ELSE 1
    END AS "R_Score",
    -- Assign Frequency Score
    CASE
      WHEN cr."Frequency" >= 4 THEN 4
      WHEN cr."Frequency" = 3 THEN 3
      WHEN cr."Frequency" = 2 THEN 2
      ELSE 1
    END AS "F_Score",
    -- Assign Monetary Score
    CASE
      WHEN cr."Monetary" >= 1000 THEN 4
      WHEN cr."Monetary" >= 500 THEN 3
      WHEN cr."Monetary" >= 100 THEN 2
      ELSE 1
    END AS "M_Score"
  FROM customer_rfm cr
),
rfm_segments AS (
  SELECT
    rs.*,
    -- Create RFM Segment by combining scores
    CAST(rs."R_Score" AS TEXT) || CAST(rs."F_Score" AS TEXT) || CAST(rs."M_Score" AS TEXT) AS "RFM_Segment",
    -- Calculate Average Sales per Order
    rs."Monetary" / rs."Frequency" AS "Average_Sales_Per_Order"
  FROM rfm_scores rs
)
SELECT
  "RFM_Segment",
  ROUND(AVG("Average_Sales_Per_Order"), 4) AS "Average_Sales_Per_Order"
FROM rfm_segments
GROUP BY "RFM_Segment"
ORDER BY "RFM_Segment";