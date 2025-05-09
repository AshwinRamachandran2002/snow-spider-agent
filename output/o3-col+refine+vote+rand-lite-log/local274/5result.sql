WITH picked_qty AS (                              -- how many units of each product were picked
    SELECT product_id,
           SUM(qty) AS picked_qty
    FROM   picking_line
    WHERE  order_id = 421
    GROUP  BY product_id
),
fifo_batches AS (                                 -- all purchase-batches for those products
    SELECT pu.product_id,
           pu.id          AS purchase_id,
           pu.purchased,
           pu.qty         AS batch_qty,
           /* running total including current batch                    */
           SUM(pu.qty) OVER (PARTITION BY pu.product_id
                             ORDER BY pu.purchased)                    AS running_qty,
           /* running total up to *before* current batch               */
           SUM(pu.qty) OVER (PARTITION BY pu.product_id
                             ORDER BY pu.purchased
                             ROWS BETWEEN UNBOUNDED PRECEDING
                                      AND 1 PRECEDING)                AS prev_running
    FROM   purchases pu
    JOIN   picked_qty pq ON pq.product_id = pu.product_id
),
consumption AS (                                  -- how much of every batch is actually used (FIFO)
    SELECT fb.product_id,
           fb.purchase_id,
           CASE                                         -- partial use of last batch
             WHEN fb.running_qty > pq.picked_qty
             THEN pq.picked_qty - COALESCE(fb.prev_running,0)
             ELSE fb.batch_qty                         -- full batch consumed
           END AS used_qty
    FROM   fifo_batches fb
    JOIN   picked_qty  pq ON pq.product_id = fb.product_id
    WHERE  COALESCE(fb.prev_running,0) < pq.picked_qty -- only batches contributing to the pick
)
SELECT  pr.id   AS product_id,
        pr.name,
        ROUND(AVG(used_qty),4) AS avg_units_picked_fifo
FROM    consumption
JOIN    products pr ON pr.id = consumption.product_id
GROUP   BY pr.id, pr.name
ORDER BY pr.id;