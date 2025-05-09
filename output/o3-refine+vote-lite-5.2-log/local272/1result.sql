/* -----------------------------------------------------------------
   Pick list for order 423
   – uses only stock that is in warehouse 1
   – older purchases are picked before newer ones
   – if two lots have the same purchase date, the smallest lot
     is taken first
------------------------------------------------------------------*/
WITH
/* 1. Order‑lines (for order 423) together with running demand
      per product.  NULL is converted to 0 so that the very first
      cumulative “start” value is 0 instead of NULL.              */
order_lines AS (
    SELECT  id                              AS orderline_id,
            product_id,
            qty                             AS line_qty,

            COALESCE(                         /* demand BEFORE  */
                SUM(qty) OVER (
                    PARTITION BY product_id
                    ORDER BY id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0)                       AS cum_need_start,

            SUM(qty) OVER (                  /* demand AFTER    */
                PARTITION BY product_id
                ORDER BY id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                               AS cum_need_end
    FROM   orderlines
    WHERE  order_id = 423
),
/* 2. Inventory that can satisfy the order:
      – warehouse 1 only
      – ordered by purchase date, then lot size, then row id
      Running totals are built in the same order; the very first
      cumulative “start” value is forced to 0 with COALESCE.      */
inv AS (
    SELECT  i.id                 AS inventory_id,
            i.product_id,
            i.qty                AS inv_qty,
            l.aisle,
            l.position,
            COALESCE(p.purchased,'9999-12-31') AS purchased,

            COALESCE(                         /* stock BEFORE    */
                SUM(i.qty) OVER (
                    PARTITION BY i.product_id
                    ORDER BY COALESCE(p.purchased,'9999-12-31'),
                             i.qty,
                             i.id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                ), 0)                       AS cum_inv_start,

            SUM(i.qty) OVER (               /* stock AFTER     */
                PARTITION BY i.product_id
                ORDER BY COALESCE(p.purchased,'9999-12-31'),
                         i.qty,
                         i.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                               AS cum_inv_end
    FROM   inventory   i
    JOIN   locations   l ON l.id = i.location_id
    LEFT   JOIN purchases p ON p.id = i.purchase_id
    WHERE  l.warehouse = 1
      AND  i.qty > 0
      AND  i.product_id IN (SELECT DISTINCT product_id
                            FROM orderlines
                            WHERE order_id = 423)
),
/* 3. Cross each order‑line with every relevant inventory row and
      calculate how much of that row is needed to cover the line.
      The quantity equals the overlap between the cumulative
      intervals   [cum_need_start ; cum_need_end)
                  [cum_inv_start  ; cum_inv_end)                 */
alloc AS (
    SELECT  ol.orderline_id,
            ol.product_id,
            inv.aisle,
            inv.position,
            inv.purchased,
            inv.inv_qty,

            CASE
                 WHEN inv.cum_inv_end   <= ol.cum_need_start THEN 0
                 WHEN inv.cum_inv_start >= ol.cum_need_end   THEN 0
                 ELSE
                       MIN(inv.cum_inv_end , ol.cum_need_end)
                     - MAX(inv.cum_inv_start, ol.cum_need_start)
            END                                          AS pick_qty
    FROM   order_lines AS ol
    JOIN   inv         ON inv.product_id = ol.product_id
)
/* 4. Final list – only rows where something is actually picked   */
SELECT  orderline_id  AS order_line,
        product_id,
        aisle,
        position,
        pick_qty
FROM    alloc
WHERE   pick_qty > 0
ORDER BY
        order_line,              /* keep order‑line sequence      */
        purchased,               /* oldest purchases first        */
        inv_qty;                 /* then smallest remaining lot   */