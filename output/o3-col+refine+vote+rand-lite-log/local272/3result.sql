WITH ordered AS (               -- quantity that must be supplied per product
    SELECT "product_id",
           SUM("qty") AS qty_ordered
    FROM   "orderlines"
    WHERE  "order_id" = 423
    GROUP  BY "product_id"
),
inv AS (                        -- inventory in warehouse-1 for those products
    SELECT  i."product_id",
            l."aisle",
            l."position",
            i."qty",
            p."purchased",
            o.qty_ordered
    FROM   "inventory"  i
    JOIN   "locations"  l ON l."id" = i."location_id"
    JOIN   "purchases"  p ON p."id" = i."purchase_id"
    JOIN   ordered      o ON o."product_id" = i."product_id"
    WHERE  l."warehouse" = 1
),
running AS (                    -- running total to decide how much to take
    SELECT  product_id,
            aisle,
            position,
            qty,
            purchased,
            qty_ordered,
            SUM(qty) OVER (PARTITION BY product_id
                           ORDER BY purchased, qty) AS run_qty
    FROM    inv
),
pick AS (                        -- exact quantity to pick from each location
    SELECT  product_id,
            aisle,
            position,
            CASE
                WHEN run_qty - qty >= qty_ordered THEN 0
                WHEN run_qty <=  qty_ordered THEN qty
                ELSE qty_ordered - (run_qty - qty)
            END AS qty_to_pick,
            purchased
    FROM    running
)
SELECT  product_id,
        aisle,
        position,
        qty_to_pick AS qty
FROM    pick
WHERE   qty_to_pick > 0          -- only the locations that will actually be picked
ORDER BY product_id, purchased, qty;