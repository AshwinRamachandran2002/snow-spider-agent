WITH "inventory_totals" AS (               -- total available (FIFO pool) per product
  SELECT
    "product_id",
    SUM("qty") AS "inv_qty_total"
  FROM "inventory"
  GROUP BY "product_id"
),
"orderline_pick" AS (                      -- qty that can actually be picked for each order‑line
  SELECT
    ol."id"            AS "orderline_id",
    ol."product_id",
    ol."qty"           AS "order_qty",
    COALESCE(it."inv_qty_total",0) AS "inv_qty_total",
    CASE
      WHEN COALESCE(it."inv_qty_total",0) >= ol."qty"
           THEN ol."qty"                   -- enough stock → whole line can be picked
      ELSE COALESCE(it."inv_qty_total",0)  -- limited stock → pick what overlaps
    END                AS "picked_qty"
  FROM "orderlines"  ol
  LEFT JOIN "inventory_totals" it
         ON it."product_id" = ol."product_id"
)
SELECT
  pr."name"                                                  AS "product_name",
  ROUND(
        AVG(
          CASE WHEN op."order_qty" = 0
               THEN 0
               ELSE CAST(op."picked_qty" AS REAL) / op."order_qty"
          END
        )
       ,4)                                                   AS "avg_pick_percentage"
FROM   "orderline_pick" op
JOIN   "products"      pr  ON pr."id" = op."product_id"
GROUP  BY pr."name"
ORDER  BY pr."name";