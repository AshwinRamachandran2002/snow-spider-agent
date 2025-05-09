WITH
-- 1. Quantities that must be picked – one row per order‑line
order_lines AS (
    SELECT
        ol.id                    AS orderline_id,
        ol.product_id,
        ol.qty                   AS qty_needed,
        /* running total of what has already been assigned
           to earlier lines for the same product            */
        COALESCE(
            SUM(ol.qty) OVER (
                PARTITION BY ol.product_id
                ORDER BY ol.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),0
        )                       AS o_start              -- 0‑based start pointer
    FROM orderlines  ol
    WHERE ol.order_id = 423
),
-- 2. Stock that can be used – only locations in warehouse 1,
--    ordered by purchase date (oldest first) and then by the
--    smallest on‑hand quantity
inv AS (
    SELECT
        i.id                    AS inv_id,
        i.product_id,
        i.qty                   AS qty_available,
        COALESCE(
            SUM(i.qty) OVER (
                PARTITION BY i.product_id
                ORDER BY pur.purchased , i.qty , i.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),0
        )                       AS inv_start,           -- 0‑based start pointer
        l.aisle,
        l.position
    FROM inventory   i
    JOIN locations   l   ON l.id = i.location_id       AND l.warehouse = 1
    JOIN purchases   pur ON pur.id = i.purchase_id
),
-- 3. Cross product order‑lines × inventory for
--    the same product and calculate the intersection size
alloc AS (
    SELECT
        o.orderline_id,
        o.product_id,
        v.aisle,
        v.position,

        /* intersection between
             order interval : [o_start , o_start+qty_needed )
             stock interval : [inv_start , inv_start+qty_available ) */
        CASE
            WHEN
                (MIN(o.o_start + o.qty_needed ,
                     v.inv_start + v.qty_available)     -- interval small‑end
                 -
                 MAX(o.o_start ,
                     v.inv_start))                      -- interval big‑start
                > 0
            THEN
                MIN(o.o_start + o.qty_needed ,
                    v.inv_start + v.qty_available)
                -
                MAX(o.o_start ,
                    v.inv_start)
            ELSE 0
        END                                            AS pick_qty
    FROM order_lines o
    JOIN inv        v  ON v.product_id = o.product_id
)
-- 4. Deliver the pick list – only rows where some quantity is needed
SELECT
    orderline_id,
    product_id,
    aisle,
    position,
    pick_qty
FROM alloc
WHERE pick_qty > 0
ORDER BY
    orderline_id,           -- keep the original order‑line sequence
    product_id,
    aisle,
    position;