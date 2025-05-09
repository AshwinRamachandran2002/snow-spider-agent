WITH
/* --- order 423 : what is needed ---------------------------------------- */
order_need AS (
    SELECT
        ol.product_id,
        SUM(ol.qty) AS need_qty               -- total ordered per product
    FROM orderlines AS ol
    WHERE ol.order_id = 423
    GROUP BY ol.product_id
),
/* --- inventory that can be used (only warehouse 1) ---------------------- */
inv_ranked AS (
    SELECT
        i.id          AS inv_id,
        i.product_id,
        i.qty         AS inv_qty,
        l.aisle,
        l.position,
        pu.purchased,                       -- purchase date = freshness
        -- priority : 1) earliest purchase‑date  2) smaller on‑hand qty  3) lowest id
        ROW_NUMBER() OVER (
            PARTITION BY i.product_id
            ORDER BY pu.purchased,
                     i.qty,
                     i.id
        ) AS rn,
        -- running total of stock following the same priority
        SUM(i.qty) OVER (
            PARTITION BY i.product_id
            ORDER BY pu.purchased,
                     i.qty,
                     i.id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_stock
    FROM inventory  AS i
    JOIN locations  AS l  ON l.id = i.location_id  AND l.warehouse = 1
    JOIN purchases  AS pu ON pu.id = i.purchase_id
),
/* --- decide how much to take from every location ----------------------- */
alloc AS (
    SELECT
        r.product_id,
        r.aisle,
        r.position,
        -- how many units to pick from this inventory row
        CASE
            WHEN r.cum_stock - r.inv_qty >= n.need_qty THEN 0                      -- already covered earlier
            WHEN r.cum_stock >= n.need_qty        THEN n.need_qty - (r.cum_stock - r.inv_qty)
            ELSE r.inv_qty                                                             -- still need more, take all
        END AS pick_qty,
        r.purchased,
        r.inv_id
    FROM inv_ranked AS r
    JOIN order_need AS n USING (product_id)
)
SELECT
    product_id,
    aisle,
    position,
    pick_qty
FROM alloc
WHERE pick_qty > 0                                   -- only lines that are actually picked
ORDER BY product_id,
         purchased,                                  -- earliest purchase first
         pick_qty,
         inv_id;