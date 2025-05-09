WITH ordered AS (              -- how much of each product the order needs
    SELECT  product_id,
            SUM(qty) AS ordered_qty
    FROM    orderlines
    WHERE   order_id = 423
    GROUP BY product_id
),
inv AS (                       -- inventory for those products in warehouse 1
    SELECT  i.id  AS inventory_id,
            i.product_id,
            i.qty AS inv_qty,
            i.location_id,
            pu.purchased
    FROM        inventory   i
    JOIN        locations   l   ON l.id = i.location_id
    JOIN        purchases   pu  ON pu.id = i.purchase_id
    WHERE       l.warehouse = 1
      AND       i.product_id IN (SELECT product_id FROM ordered)
),
inv_ranked AS (                -- running‑stock BEFORE the current row
    SELECT  inv.*,
            o.ordered_qty,
            COALESCE(
                SUM(inv_qty) OVER (
                    PARTITION BY product_id
                    ORDER BY purchased, inv_qty, inventory_id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ),0
            ) AS cum_before
    FROM    inv
    JOIN    ordered o USING (product_id)
),
calc AS (                       -- how much to pick from each location
    SELECT  *,
            CASE
                WHEN ordered_qty - cum_before <= 0        THEN 0
                WHEN ordered_qty - cum_before >= inv_qty  THEN inv_qty
                ELSE ordered_qty - cum_before
            END AS pick_qty
    FROM    inv_ranked
)
SELECT  c.product_id,
        l.aisle,
        l.position,
        c.pick_qty
FROM    calc AS c
JOIN    locations l ON l.id = c.location_id
WHERE   c.pick_qty > 0            -- only the locations we actually pick from
ORDER BY c.product_id,
         c.purchased,             -- FIFO: earliest purchase first
         c.inv_qty,               -- smaller lots before bigger ones
         c.inventory_id;          -- deterministic tie‑break