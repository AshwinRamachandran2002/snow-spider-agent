WITH
-- Get total inventory per product
product_inventory AS (
  SELECT
    I."product_id",
    SUM(I."qty") AS total_inventory_qty
  FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" I
  GROUP BY I."product_id"
),
-- Get order lines with cumulative ordered quantity per product
orderlines_cumulative AS (
  SELECT
    OL."product_id",
    OL."order_id",
    OL."qty" AS "ordered_qty",
    SUM(OL."qty") OVER (
      PARTITION BY OL."product_id"
      ORDER BY OL."order_id"
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS "cumulative_order_qty_before"
  FROM "ORACLE_SQL"."ORACLE_SQL"."ORDERLINES" OL
),
-- Compute pick percentage per order line
orderlines_pick AS (
  SELECT
    OL."product_id",
    OL."order_id",
    OL."ordered_qty",
    COALESCE(OL."cumulative_order_qty_before", 0) AS "cumulative_order_qty_before",
    PI.total_inventory_qty,
    (PI.total_inventory_qty - COALESCE(OL."cumulative_order_qty_before", 0)) AS "available_inventory",
    LEAST(
      OL."ordered_qty",
      GREATEST(0, PI.total_inventory_qty - COALESCE(OL."cumulative_order_qty_before", 0))
    ) AS "picked_qty",
    (LEAST(
      OL."ordered_qty",
      GREATEST(0, PI.total_inventory_qty - COALESCE(OL."cumulative_order_qty_before", 0))
    ) / OL."ordered_qty") * 100 AS "pick_percentage"
  FROM orderlines_cumulative OL
  JOIN product_inventory PI ON OL."product_id" = PI."product_id"
)
-- Now, compute average pick percentage per product and join with product names
SELECT
  P."name" AS "Product_Name",
  ROUND(PP.average_pick_percentage, 4) AS "Average_Pick_Percentage"
FROM (
  SELECT
    OL."product_id",
    AVG(OL."pick_percentage") AS average_pick_percentage
  FROM orderlines_pick OL
  GROUP BY OL."product_id"
) PP
JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" P ON PP."product_id" = P."id"
ORDER BY P."name";