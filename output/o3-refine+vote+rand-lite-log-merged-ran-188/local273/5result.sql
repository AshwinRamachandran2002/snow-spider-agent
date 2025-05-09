/*  Average pick-percentage per product – FIFO rule:
    • Only the inventory row that belongs to the EARLIEST purchase for each
      (location,product) is kept.
    • If several rows share that earliest date we keep the one with the
      SMALLEST available quantity.
    • Picked quantity is the overlap between the requested quantity on each
      picking-line and the quantity in that FIFO inventory row.
    • For each (order,product) we compare total picked with total ordered,
      then take the average of those percentages for every product name.          */

WITH
-- 1) Earliest purchase date per (location, product)
earliest AS (
    SELECT   i.location_id,
             i.product_id,
             MIN(p.purchased) AS first_purchased
    FROM     inventory  AS i
    JOIN     purchases  AS p ON p.id = i.purchase_id
    GROUP BY i.location_id, i.product_id
),

-- 2) Within the earliest date pick the row with the smallest quantity
min_qty AS (
    SELECT   i.location_id,
             i.product_id,
             MIN(i.qty) AS min_qty
    FROM     inventory  AS i
    JOIN     purchases  AS p ON p.id = i.purchase_id
    JOIN     earliest   AS e
           ON e.location_id   = i.location_id
          AND e.product_id    = i.product_id
          AND e.first_purchased = p.purchased
    GROUP BY i.location_id, i.product_id
),

-- 3) FIFO inventory: earliest date + smallest quantity
fifo_inv AS (
    SELECT i.*
    FROM   inventory  AS i
    JOIN   purchases  AS p ON p.id = i.purchase_id
    JOIN   earliest   AS e
           ON e.location_id   = i.location_id
          AND e.product_id    = i.product_id
          AND e.first_purchased = p.purchased
    JOIN   min_qty    AS q
           ON q.location_id = i.location_id
          AND q.product_id  = i.product_id
          AND q.min_qty     = i.qty
),

-- 4) What could actually be picked from those FIFO rows
picked AS (
    SELECT  pl.order_id,
            pl.product_id,
            MIN(pl.qty, fi.qty) AS picked_qty          -- overlap
    FROM    picking_line AS pl
    JOIN    fifo_inv     AS fi
           ON fi.location_id = pl.location_id
          AND fi.product_id  = pl.product_id
),

-- 5) Ordered quantity (per order & product)
ordered AS (
    SELECT  order_id,
            product_id,
            SUM(qty) AS ordered_qty
    FROM    orderlines
    GROUP BY order_id, product_id
),

-- 6) Pick-percentage per order & product
percentages AS (
    SELECT  o.order_id,
            o.product_id,
            (1.0 * COALESCE(SUM(p.picked_qty),0)) / SUM(o.ordered_qty) AS pct
    FROM    ordered o
    LEFT JOIN picked p
           ON p.order_id  = o.order_id
          AND p.product_id = o.product_id
    GROUP BY o.order_id, o.product_id
)

-- 7) Average percentage per product name
SELECT  pr.name                                       AS product_name,
        ROUND(AVG(pct) * 100, 2) || '%'               AS avg_pick_percentage
FROM    percentages   AS perc
JOIN    products      AS pr  ON pr.id = perc.product_id
GROUP BY pr.name
ORDER  BY pr.name;