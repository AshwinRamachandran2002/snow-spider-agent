/*  Which products were picked for order 421 and, following the FIFO
    (first-in, first-out) sequence of the actual pick-events, what is the
    average quantity that was picked for every product?                                 */

WITH fifo_picks AS (           /* keep only the real pick events, in pick-time order */
    SELECT
        pl."product_id",
        pl."qty",
        lg."log_time"
    FROM ORACLE_SQL.ORACLE_SQL.PICKING_LINE pl
    JOIN ORACLE_SQL.ORACLE_SQL.PICKING_LOG  lg
          ON lg."picklist_id" = pl."picklist_id"
         AND lg."pickline_no" = pl."line_no"
         AND lg."activity"     = 'P'          -- ‘P’ = a product was actually picked
    WHERE pl."order_id" = 421
)
SELECT
    "product_id",
    AVG("qty") AS "avg_picked_qty"
FROM fifo_picks
GROUP BY "product_id"
ORDER BY "product_id";