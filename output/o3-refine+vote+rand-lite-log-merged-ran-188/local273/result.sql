WITH fifo AS (
    SELECT
        pl.picklist_id,
        pl.line_no,
        pl.product_id,
        pl.qty                                   AS pick_qty,
        i.qty                                    AS inv_qty,
        MIN(pl.qty, i.qty)                       AS overlap_qty,
        ROW_NUMBER() OVER (
            PARTITION BY pl.picklist_id, pl.line_no
            ORDER BY pu.purchased ASC, i.qty ASC
        )                                        AS rn
    FROM picking_line  AS pl
    JOIN inventory     AS i   ON i.location_id = pl.location_id
                             AND i.product_id  = pl.product_id
    JOIN purchases     AS pu  ON pu.id = i.purchase_id
)
SELECT
    pr.name                                            AS product_name,
    ROUND(AVG(1.0 * overlap_qty / inv_qty), 4)         AS avg_pick_percentage
FROM fifo
JOIN products AS pr ON pr.id = fifo.product_id
WHERE fifo.rn = 1                      -- keep only the first (FIFO) batch
GROUP BY pr.name
ORDER BY pr.name;