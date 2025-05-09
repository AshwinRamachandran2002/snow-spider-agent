-- Which products were picked for order 421 and the average number of units picked
-- (FIFO = picks are evaluated in the chronological order they were executed)

WITH fifo_picks AS (
    SELECT
        pl."product_id",
        pl."qty",                              -- units picked in this action
        lg."log_time",
        ROW_NUMBER() OVER (
            ORDER BY TO_TIMESTAMP(lg."log_time", 'YYYY-MM-DD HH24:MI:SS')
        ) AS fifo_rank                        -- chronological sequence (FIFO)
    FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE" pl
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PICKING_LOG"  lg
      ON  pl."picklist_id" = lg."picklist_id"
      AND pl."line_no"     = lg."pickline_no"
    WHERE pl."order_id" = 421                 -- only the requested order
      AND lg."activity" = 'P'                 -- real pick actions
)
SELECT
    "product_id",
    AVG("qty") AS "avg_units_picked"
FROM fifo_picks
GROUP BY "product_id"
ORDER BY "product_id";