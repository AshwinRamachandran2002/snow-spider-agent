/*  Average quantity per product for Order 421 – based on the FIRST (FIFO) pick
    recorded for every pick-line actually executed                                */

WITH first_picks AS (
    SELECT
        lg."picklist_id",
        lg."pickline_no",
        pl."product_id",
        pl."qty",
        ROW_NUMBER() OVER (PARTITION BY lg."picklist_id", lg."pickline_no"
                           ORDER BY lg."log_time") AS rn   -- keep the very first P-log per line
    FROM ORACLE_SQL.ORACLE_SQL."PICKING_LOG"   lg
    JOIN ORACLE_SQL.ORACLE_SQL."PICKING_LINE"  pl
         ON  pl."picklist_id" = lg."picklist_id"
         AND pl."line_no"    = lg."pickline_no"
    WHERE lg."activity" = 'P'          -- only real pick events
      AND pl."order_id" = 421          -- target order
)

SELECT
    "product_id",
    AVG("qty") AS "avg_qty_fifo"
FROM first_picks
WHERE rn = 1                         -- FIFO: only the earliest pick per line
GROUP BY "product_id"
ORDER BY "product_id";