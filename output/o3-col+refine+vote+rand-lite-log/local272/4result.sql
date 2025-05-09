WITH need AS (                         -- total quantity required per product
    SELECT product_id,
           SUM(qty) AS need_qty
    FROM orderlines
    WHERE order_id = 423
    GROUP BY product_id
),
inv AS (                               -- every matching inventory row in warehouse 1
    SELECT i.id          AS inv_id,
           i.product_id,
           i.qty         AS stock_qty,
           p.purchased,
           l.aisle,
           l.position
    FROM inventory  AS i
    JOIN purchases  AS p ON p.id = i.purchase_id
    JOIN locations  AS l ON l.id = i.location_id
    WHERE l.warehouse = 1
      AND i.product_id IN (SELECT product_id FROM need)
),
ranked AS (                            -- running total by product (oldest-first, smallest lots)
    SELECT inv.*,
           need.need_qty,
           SUM(stock_qty) OVER (
                 PARTITION BY product_id
                 ORDER BY purchased, stock_qty, inv_id
           ) AS cum_qty
    FROM inv
    JOIN need USING (product_id)
)
SELECT product_id,
       aisle,
       position,
       CASE                                    -- exact quantity to pick from this location
            WHEN cum_qty - stock_qty >= need_qty
                 THEN 0
            ELSE MIN(stock_qty,
                     need_qty - (cum_qty - stock_qty))
       END AS pick_qty
FROM ranked
WHERE cum_qty - stock_qty < need_qty           -- only rows that contribute to the pick
ORDER BY product_id, purchased, stock_qty, inv_id;