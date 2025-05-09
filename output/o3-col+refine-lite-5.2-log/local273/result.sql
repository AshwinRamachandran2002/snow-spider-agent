/*  Average pick‑percentage per product name (FIFO logic) */
WITH pick_overlap AS (
    /* overlap between what was picked and what was available
       for every pick‑line row                                        */
    SELECT
        pl.order_id,
        pl.product_id,
        /* overlap = the lesser of requested qty on the line
           and the inventory quantity of the location picked
           (location already selected FIFO by the WMS)               */
        CASE
            WHEN pl.qty <= i.qty THEN pl.qty
            ELSE i.qty
        END AS picked_overlap
    FROM   picking_line AS pl
    JOIN   inventory    AS i
           ON  i.location_id = pl.location_id
           AND i.product_id  = pl.product_id
),
order_pick_pct AS (
    /* roll up to order‑product level and compute pick‑percentage     */
    SELECT
        ol.order_id,
        ol.product_id,
        SUM(picked_overlap) * 1.0 / ol.qty      AS pick_pct
    FROM   orderlines   AS ol
    JOIN   pick_overlap AS po
           ON  po.order_id   = ol.order_id
           AND po.product_id = ol.product_id
    GROUP BY
        ol.order_id,
        ol.product_id
)
SELECT
    pr.name                           AS product_name,
    AVG(op.pick_pct)                  AS avg_pick_percentage
FROM   order_pick_pct  AS op
JOIN   products        AS pr  ON pr.id = op.product_id
GROUP  BY pr.name
ORDER  BY pr.name;