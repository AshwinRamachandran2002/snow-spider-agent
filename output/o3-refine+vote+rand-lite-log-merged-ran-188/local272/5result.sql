WITH ordered AS (                /* quantity that must be shipped for the order           */
  SELECT "product_id",
         SUM("qty") AS ordered_qty
  FROM   "orderlines"
  WHERE  "order_id" = 423
  GROUP  BY "product_id"
),
inv AS (                         /* all inventory for those products in warehouse 1       */
  SELECT i."id"                 AS inv_id,
         i."product_id",
         i."qty"                AS lot_qty,
         p."purchased",
         l."aisle",
         l."position"
  FROM   "inventory"  AS i
  JOIN   "purchases"  AS p ON p."id" = i."purchase_id"
  JOIN   "locations"  AS l ON l."id" = i."location_id"
  WHERE  l."warehouse" = 1
    AND  i."product_id" IN (SELECT product_id FROM ordered)
),
inv_cum AS (                     /* running total per product in strict FIFO order        */
  SELECT inv.*,
         SUM(lot_qty) OVER (
             PARTITION BY product_id
             ORDER BY purchased, lot_qty, inv_id
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
         )                       AS cum_qty            /* running total incl. current lot */
  FROM   inv
),
pick_plan AS (                   /* decide how much we need from each individual lot      */
  SELECT product_id,
         aisle,
         position,
         CASE
           WHEN ordered_qty - (cum_qty - lot_qty) <= 0 THEN 0                     -- nothing left to pick
           WHEN ordered_qty - (cum_qty - lot_qty) >= lot_qty THEN lot_qty         -- take whole lot
           ELSE ordered_qty - (cum_qty - lot_qty)                                 -- take the remainder
         END AS pick_qty
  FROM   inv_cum
  JOIN   ordered USING (product_id)
)
SELECT product_id,
       aisle,
       position,
       pick_qty
FROM   pick_plan
WHERE  pick_qty > 0                       /* only the lots we actually have to pick */
ORDER  BY product_id,
         /* keep the same FIFO sequence */
         (SELECT p."purchased"
          FROM   "inventory"  i2
          JOIN   "purchases"  p ON p."id" = i2."purchase_id"
          JOIN   "locations"  l2 ON l2."id" = i2."location_id"
          WHERE  i2."product_id" = pick_plan.product_id
            AND  l2."aisle"     = pick_plan.aisle
            AND  l2."position"  = pick_plan.position
          LIMIT 1),
         position;