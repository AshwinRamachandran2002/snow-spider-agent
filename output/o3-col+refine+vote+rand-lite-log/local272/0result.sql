WITH needed AS (                                  -- how much of each product the order requires
    SELECT product_id,
           SUM(qty) AS qty_needed
    FROM   orderlines
    WHERE  order_id = 423
    GROUP  BY product_id
),
inv AS (                                          -- all relevant inventory lines (warehouse-1 only)
    SELECT  i.id         AS inv_id,
            i.product_id,
            i.qty        AS inv_qty,
            p.purchased,                         -- purchase date (to age the stock)
            l.aisle,
            l.position,
            SUM(i.qty) OVER (                    -- running total in priority order
                PARTITION BY i.product_id
                ORDER BY   p.purchased, i.qty
            ) AS cum_qty
    FROM    inventory  AS i
    JOIN    purchases  AS p ON p.id = i.purchase_id
    JOIN    locations  AS l ON l.id = i.location_id
    WHERE   l.warehouse = 1
      AND   i.product_id IN (SELECT product_id FROM needed)
)
SELECT  inv.product_id,
        inv.aisle,
        inv.position,
        CASE                                            -- quantity to pick from this location
            WHEN inv.cum_qty - inv.inv_qty >= needed.qty_needed THEN 0
            WHEN inv.cum_qty               <= needed.qty_needed THEN inv.inv_qty
            ELSE needed.qty_needed - (inv.cum_qty - inv.inv_qty)
        END AS pick_qty
FROM    inv
JOIN    needed USING (product_id)
WHERE   CASE
            WHEN inv.cum_qty - inv.inv_qty >= needed.qty_needed THEN 0
            WHEN inv.cum_qty               <= needed.qty_needed THEN inv.inv_qty
            ELSE needed.qty_needed - (inv.cum_qty - inv.inv_qty)
        END > 0                                          -- keep only lines where something is picked
ORDER BY inv.product_id,
         inv.purchased,
         inv.inv_qty;