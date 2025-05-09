WITH order_products AS (            -- quantity needed per product
    SELECT product_id,
           SUM(qty) AS need_qty
    FROM   orderlines
    WHERE  order_id = 423
    GROUP  BY product_id
),
inv AS (                            -- stock in warehouse 1
    SELECT i.product_id,
           i.qty              AS inv_qty,
           p.purchased,
           l.aisle,
           l.position
    FROM   inventory  AS i
    JOIN   purchases  AS p ON p.id = i.purchase_id
    JOIN   locations  AS l ON l.id = i.location_id
    WHERE  l.warehouse = 1
      AND  i.product_id IN (SELECT product_id FROM order_products)
),
ranked AS (                         -- running total per product (FIFO + small batches)
    SELECT inv.*,
           SUM(inv_qty) OVER (PARTITION BY product_id
                              ORDER BY date(purchased), inv_qty) AS cum_inv
    FROM   inv
),
picks AS (                          -- determine pick quantity per location
    SELECT r.product_id,
           r.aisle,
           r.position,
           CASE
               WHEN r.cum_inv - r.inv_qty >= op.need_qty THEN 0
               WHEN r.cum_inv >= op.need_qty
                    THEN op.need_qty - (r.cum_inv - r.inv_qty)
               ELSE r.inv_qty
           END AS pick_qty
    FROM   ranked r
    JOIN   order_products op USING (product_id)
)
SELECT product_id,
       aisle,
       position,
       pick_qty
FROM   picks
WHERE  pick_qty > 0
ORDER  BY product_id,
          date((SELECT purchased FROM purchases WHERE id = (
                 SELECT purchase_id FROM inventory
                 WHERE product_id = picks.product_id
                   AND qty = pick_qty
                 LIMIT 1))),  -- keep FIFO order in final output
          pick_qty;