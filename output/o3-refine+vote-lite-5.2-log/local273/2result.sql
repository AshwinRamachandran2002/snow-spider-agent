WITH first_inventory AS (
    /* FIFO: one inventory record per (location,product) –
       earliest purchase date first, then smallest quantity        */
    SELECT
        i.location_id,
        i.product_id,
        i.qty                                          AS inv_qty,
        ROW_NUMBER() OVER (
            PARTITION BY i.location_id, i.product_id
            ORDER BY p.purchased ASC, i.qty ASC
        )                                              AS rn
    FROM inventory  i
    JOIN purchases p ON p.id = i.purchase_id
),
fifo_inventory AS (
    /* keep only the chosen FIFO‐row for every location/product */
    SELECT location_id,
           product_id,
           inv_qty
    FROM first_inventory
    WHERE rn = 1
),
pick_vs_inv AS (
    /* compare what was picked with what that FIFO inventory row contains;
       only count the overlapping amount                                */
    SELECT
        pl.order_id,
        pl.product_id,
        ol.qty                                 AS order_qty,
        CASE
            WHEN pl.qty < fi.inv_qty THEN pl.qty
            ELSE fi.inv_qty
        END                                    AS picked_overlap
    FROM picking_line pl
    JOIN fifo_inventory fi
         ON fi.location_id = pl.location_id
        AND fi.product_id  = pl.product_id
    JOIN orderlines ol
         ON ol.order_id   = pl.order_id
        AND ol.product_id = pl.product_id
),
order_product_pick AS (
    /* total picked for every (order,product) versus what was ordered   */
    SELECT
        order_id,
        product_id,
        SUM(picked_overlap)                 AS picked_total,
        MAX(order_qty)                      AS order_qty
    FROM pick_vs_inv
    GROUP BY order_id, product_id
),
pick_percentage AS (
    /* pick percentage per order/product                                */
    SELECT
        product_id,
        picked_total * 1.0 / order_qty      AS pick_pct
    FROM order_product_pick
)
SELECT
    pr.name                               AS product_name,
    ROUND(AVG(pick_pct) * 100, 4)         AS avg_pick_percentage
FROM pick_percentage pp
JOIN products pr ON pr.id = pp.product_id
GROUP BY pr.name
ORDER BY pr.name;