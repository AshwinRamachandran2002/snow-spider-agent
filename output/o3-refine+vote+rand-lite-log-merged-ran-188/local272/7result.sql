WITH ordered AS (                                    -- quantity required for each product on order 423
    SELECT "product_id",
           SUM("qty") AS qty_needed
    FROM   "orderlines"
    WHERE  "order_id" = 423
    GROUP  BY "product_id"
),
inv AS (                                             -- inventory in W-1, prioritised by age & small lots
    SELECT  i."product_id",
            i."qty"                    AS stock_qty,
            pu."purchased",
            l."aisle",
            l."position",
            SUM(i."qty") OVER (PARTITION BY i."product_id"
                               ORDER BY pu."purchased", i."qty", i."id") AS running_stock
    FROM    "inventory"  i
    JOIN    "locations"  l   ON l."id" = i."location_id"
    JOIN    "purchases"  pu  ON pu."id" = i."purchase_id"
    WHERE   l."warehouse" = 1
      AND   i."product_id" IN (SELECT "product_id" FROM ordered)
),
pick AS (                                            -- calculate how much to pick from each location
    SELECT  inv."product_id",
            inv."aisle",
            inv."position",
            inv."purchased",
            inv.stock_qty,
            CASE
                 WHEN (inv.running_stock - inv.stock_qty) >=
                      (SELECT qty_needed FROM ordered o
                       WHERE o."product_id" = inv."product_id")
                 THEN 0
                 WHEN inv.running_stock <=
                      (SELECT qty_needed FROM ordered o
                       WHERE o."product_id" = inv."product_id")
                 THEN inv.stock_qty
                 ELSE (SELECT qty_needed FROM ordered o
                       WHERE o."product_id" = inv."product_id")
                      - (inv.running_stock - inv.stock_qty)
            END AS qty_to_pick
    FROM   inv
)
SELECT  "product_id",
        "aisle",
        "position",
        qty_to_pick
FROM    pick
WHERE   qty_to_pick > 0                     -- only locations we actually pick from
ORDER BY "product_id",
         "purchased",                       -- oldest lots first
         stock_qty;                         -- then the smaller ones