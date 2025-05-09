WITH order_quantities AS (
    SELECT "product_id", SUM("qty") AS "ordered_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."ORDERLINES"
    WHERE "order_id" = 423
    GROUP BY "product_id"
),
inventory_records AS (
    SELECT
      i."product_id",
      l."aisle",
      l."position",
      i."qty",
      pchs."purchased"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN "ORACLE_SQL"."ORACLE_SQL"."LOCATIONS" l ON i."location_id" = l."id"
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" pchs ON i."purchase_id" = pchs."id"
    WHERE l."warehouse" = 1
      AND i."product_id" IN (SELECT "product_id" FROM order_quantities)
      AND i."qty" > 0
),
inventory_with_cumulative AS (
    SELECT
      ir.*,
      oq."ordered_qty",
      SUM(ir."qty") OVER (
          PARTITION BY ir."product_id" 
          ORDER BY ir."purchased", ir."qty"
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS "cumulative_qty"
    FROM inventory_records ir
    JOIN order_quantities oq ON ir."product_id" = oq."product_id"
),
inventory_final AS (
  SELECT
    iwc."product_id",
    iwc."aisle",
    iwc."position",
    iwc."purchased",
    iwc."qty",
    CASE
      WHEN (iwc."cumulative_qty" - iwc."qty") >= iwc."ordered_qty" THEN 0
      WHEN iwc."cumulative_qty" <= iwc."ordered_qty" THEN iwc."qty"
      ELSE iwc."ordered_qty" - (iwc."cumulative_qty" - iwc."qty")
    END AS "qty_to_pick"
  FROM inventory_with_cumulative iwc
)
SELECT
  "product_id",
  "aisle",
  "position",
  ROUND("qty_to_pick", 4) AS "qty_to_pick"
FROM inventory_final
WHERE "qty_to_pick" > 0
ORDER BY "product_id", "purchased", "qty";