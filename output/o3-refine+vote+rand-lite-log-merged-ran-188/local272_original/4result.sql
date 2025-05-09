WITH
requested AS (   
    SELECT  ol.product_id,
            SUM(ol.qty) AS qty_needed
    FROM    orderlines AS ol
    WHERE   ol.order_id = 423
    GROUP BY ol.product_id
),
inv AS (
    SELECT  i.id                    AS inv_id,
            i.product_id,
            i.qty                   AS inv_qty,
            l.aisle,
            l.position,
            pu.purchased            AS purchased,
            ROW_NUMBER() OVER (
                PARTITION BY i.product_id
                ORDER BY pu.purchased, i.qty, i.id
            )                       AS prio
    FROM        inventory  AS i
    JOIN        locations  AS l  ON l.id       = i.location_id
    JOIN        purchases  AS pu ON pu.id      = i.purchase_id
    WHERE       l.warehouse = 1
),
inv_cum AS (
    SELECT  inv.*,
            SUM(inv.inv_qty) OVER (
                PARTITION BY inv.product_id
                ORDER BY      inv.prio
            )                       AS cum_qty
    FROM    inv
),
alloc AS (
    SELECT  ic.product_id,
            ic.aisle,
            ic.position,
            ic.prio,
            ic.purchased,
            ic.inv_qty,
            CASE
                   WHEN ic.cum_qty - ic.inv_qty >= r.qty_needed
                   THEN 0
                   WHEN ic.cum_qty <= r.qty_needed
                   THEN ic.inv_qty
                   ELSE r.qty_needed - (ic.cum_qty - ic.inv_qty)
            END                     AS qty_to_pick
    FROM        inv_cum  AS ic
    JOIN        requested AS r  ON r.product_id = ic.product_id
)
SELECT  product_id,
        aisle,
        position,
        qty_to_pick
FROM    alloc
WHERE   qty_to_pick > 0
ORDER BY product_id,
         prio;