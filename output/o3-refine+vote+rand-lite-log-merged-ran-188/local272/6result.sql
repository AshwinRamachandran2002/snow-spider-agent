WITH
-- how much of each product the order needs
req AS (
    SELECT "product_id",
           SUM("qty") AS qty_required
    FROM "orderlines"
    WHERE "order_id" = 423
    GROUP BY "product_id"
),
-- warehouse-1 inventory for those products,
-- FIFO ordered (oldest purchase first, then smallest lots)
inv AS (
    SELECT  i."id"  AS inv_id,
            i."product_id",
            p."purchased",
            l."aisle",
            l."position",
            i."qty",
            SUM(i."qty") OVER (PARTITION BY i."product_id"
                               ORDER BY p."purchased", i."qty", i."id") AS running_qty
    FROM "inventory"  AS i
    JOIN "purchases"  AS p ON p."id" = i."purchase_id"
    JOIN "locations"  AS l ON l."id" = i."location_id"
    WHERE l."warehouse" = 1
      AND i."product_id" IN (SELECT "product_id" FROM req)
)
SELECT  inv."product_id",
        inv."aisle",
        inv."position",
        -- quantity to pick from this location
        CASE
            WHEN inv.running_qty - inv."qty" >= req.qty_required THEN 0             -- already satisfied
            WHEN inv.running_qty <= req.qty_required            THEN inv."qty"      -- take whole lot
            ELSE req.qty_required - (inv.running_qty - inv."qty")                   -- take just what is left to satisfy
        END AS qty_to_pick
FROM   inv
JOIN   req ON req."product_id" = inv."product_id"
WHERE  -- keep only rows where something must be picked
       CASE
           WHEN inv.running_qty - inv."qty" >= req.qty_required THEN 0
           WHEN inv.running_qty <= req.qty_required            THEN inv."qty"
           ELSE req.qty_required - (inv.running_qty - inv."qty")
       END > 0
ORDER BY inv."product_id",
         inv."purchased",
         inv."qty",
         inv.inv_id;