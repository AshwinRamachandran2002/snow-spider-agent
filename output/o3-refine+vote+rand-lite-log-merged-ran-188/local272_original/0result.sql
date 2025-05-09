/* -----------------------------------------------------------------
   Create a pick‑plan for order 423

   • pick only from warehouse 1
   • take the oldest (earlier “purchased”) and – inside that date –
     the smallest inventory lots first
   • if a product is listed several times in the order we respect the
     order‑line sequence and allocate cumulatively
-------------------------------------------------------------------*/
WITH
/* ---- order lines of order 423 enriched with cumulative figures ---- */
orderlines_c AS (
    SELECT  ol.id  AS orderline_id,
            ol.order_id,
            ol.product_id,
            ol.qty,
            COALESCE(
                SUM(ol.qty) OVER (
                    PARTITION BY ol.product_id
                    ORDER BY ol.id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ),0
            )                            AS ol_cum_prev,   -- quantity before this line
            SUM(ol.qty) OVER (
                PARTITION BY ol.product_id
                ORDER BY ol.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                            AS ol_cum_end     -- quantity incl. this line
    FROM   orderlines ol
    WHERE  ol.order_id = 423
),
/* ---- inventory in warehouse 1 with cumulative figures ---- */
inventories_c AS (
    SELECT  inv.id          AS inventory_id,
            inv.product_id,
            inv.qty,
            loc.aisle,
            loc.position,
            p.purchased,                               -- purchase date (may be NULL)
            COALESCE(
                SUM(inv.qty) OVER (
                    PARTITION BY inv.product_id
                    ORDER BY p.purchased, inv.qty, inv.id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ),0
            )                     AS inv_cum_prev,     -- quantity before this lot
            SUM(inv.qty) OVER (
                PARTITION BY inv.product_id
                ORDER BY p.purchased, inv.qty, inv.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                     AS inv_cum_end        -- quantity incl. this lot
    FROM   inventory  inv
    JOIN   locations  loc ON loc.id = inv.location_id
                         AND loc.warehouse = 1
    LEFT JOIN purchases p  ON p.id  = inv.purchase_id
    WHERE  inv.qty > 0
),
/* ---- intersect order cum‑ranges with inventory cum‑ranges --------- */
alloc AS (
    SELECT  o.order_id,
            o.orderline_id,
            o.product_id,
            i.aisle,
            i.position,
            i.purchased,
            (CASE WHEN i.inv_cum_end < o.ol_cum_end THEN i.inv_cum_end
                  ELSE o.ol_cum_end END)
          - (CASE WHEN i.inv_cum_prev > o.ol_cum_prev THEN i.inv_cum_prev
                  ELSE o.ol_cum_prev END)   AS pick_qty
    FROM    orderlines_c  o
    JOIN    inventories_c i
          ON i.product_id  = o.product_id
         AND i.inv_cum_end > o.ol_cum_prev   -- inventory lot enters the needed range
         AND i.inv_cum_prev < o.ol_cum_end   -- inventory lot not fully before it
)
/* -------------- final pick list ------------------------------------ */
SELECT  order_id,
        orderline_id,
        product_id,
        aisle,
        position,
        ROUND(pick_qty,4) AS pick_qty
FROM    alloc
WHERE   pick_qty > 0
ORDER BY orderline_id,            -- preserve order‑line sequence
         purchased,               -- oldest purchase first
         pick_qty, aisle, position;