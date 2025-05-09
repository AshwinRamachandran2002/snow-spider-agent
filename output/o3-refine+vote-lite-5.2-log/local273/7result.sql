WITH inv_fifo AS (          -- every pick‑line matched with ALL inventory lines of same product
    SELECT 
        pl."picklist_id",
        pl."line_no",
        pl."product_id",
        pl."qty"                       AS order_qty,
        inv."id"                       AS inv_id,
        inv."qty"                      AS inv_qty,
        pu."purchased"                 AS purchased_date
    FROM "picking_line"  pl
    JOIN "inventory"     inv ON inv."product_id" = pl."product_id"
    JOIN "purchases"     pu  ON pu."id"          = inv."purchase_id"
),
cum AS (                     -- running sum of inventory quantities in strict FIFO order
    SELECT
        *,
        SUM(inv_qty) OVER (
            PARTITION BY picklist_id, line_no
            ORDER BY purchased_date, inv_qty, inv_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cum_before
    FROM inv_fifo
),
alloc AS (                   -- quantity actually picked from each inventory line
    SELECT
        *,
        (COALESCE(cum_before,0) + inv_qty) AS cum_after,
        CASE
            WHEN COALESCE(cum_before,0) >= order_qty                      THEN 0
            WHEN (COALESCE(cum_before,0) + inv_qty) <= order_qty          THEN inv_qty
            ELSE order_qty - COALESCE(cum_before,0)
        END AS picked_from_this
    FROM cum
),
used AS (                     -- keep only inventory lines that contribute to the pick
    SELECT *
    FROM   alloc
    WHERE  picked_from_this > 0
),
pick_pct AS (                 -- pick‑percentage of each utilised inventory line
    SELECT
        product_id,
        CAST(picked_from_this AS REAL) / inv_qty AS pick_percentage
    FROM used
)
SELECT
    pr."name"                       AS product_name,
    ROUND(AVG(pick_percentage),4)   AS avg_pick_percentage
FROM   pick_pct  pp
JOIN   products  pr ON pr.id = pp.product_id
GROUP  BY pr."name"
ORDER  BY pr."name";