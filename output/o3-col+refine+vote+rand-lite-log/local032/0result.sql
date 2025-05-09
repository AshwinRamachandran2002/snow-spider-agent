WITH delivered_orders AS (
    SELECT "order_id",
           "customer_id"
    FROM   "olist_orders"
    WHERE  "order_status" = 'delivered'
)

SELECT 'Most distinct customers' AS description,
       seller_id,
       metric_value               AS value
FROM (
      SELECT oi."seller_id",
             COUNT(DISTINCT c."customer_unique_id") AS metric_value
      FROM   delivered_orders         AS d
      JOIN   "olist_order_items"      AS oi ON d."order_id" = oi."order_id"
      JOIN   "olist_customers"        AS c  ON d."customer_id" = c."customer_id"
      GROUP  BY oi."seller_id"
      ORDER  BY metric_value DESC
      LIMIT  1
)

UNION ALL

SELECT 'Highest profit',
       seller_id,
       metric_value
FROM (
      SELECT oi."seller_id",
             SUM(oi."price" - oi."freight_value") AS metric_value
      FROM   delivered_orders        AS d
      JOIN   "olist_order_items"     AS oi ON d."order_id" = oi."order_id"
      GROUP  BY oi."seller_id"
      ORDER  BY metric_value DESC
      LIMIT  1
)

UNION ALL

SELECT 'Most distinct orders',
       seller_id,
       metric_value
FROM (
      SELECT oi."seller_id",
             COUNT(DISTINCT oi."order_id") AS metric_value
      FROM   delivered_orders        AS d
      JOIN   "olist_order_items"     AS oi ON d."order_id" = oi."order_id"
      GROUP  BY oi."seller_id"
      ORDER  BY metric_value DESC
      LIMIT  1
)

UNION ALL

SELECT 'Most 5-star reviews',
       seller_id,
       metric_value
FROM (
      SELECT oi."seller_id",
             COUNT(DISTINCT r."review_id") AS metric_value
      FROM   delivered_orders        AS d
      JOIN   "olist_order_items"     AS oi ON d."order_id" = oi."order_id"
      JOIN   "olist_order_reviews"   AS r  ON d."order_id" = r."order_id"
      WHERE  r."review_score" = 5
      GROUP  BY oi."seller_id"
      ORDER  BY metric_value DESC
      LIMIT  1
);