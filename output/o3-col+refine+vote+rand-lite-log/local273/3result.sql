/*  Average pick–percentage per product.
    --------------------------------------------------------------
    1. order_tot   – total ordered quantity per (order, product)
    2. pick_tot    – quantity that was actually picked, but only from
                     those inventory lots that the WMS chose according
                     to FIFO (earliest purchase-date, then smallest lot)
                     – this is guaranteed by the join to inventory /
                       purchases behind every picking_line entry.
    3. pct_per_order – pick-percentage for each (order, product)
    4. FINAL        – average pick-percentage per product name
*/
WITH order_tot AS (
    SELECT   "order_id",
             "product_id",
             SUM("qty") AS "ordered_qty"
    FROM     "orderlines"
    GROUP BY "order_id", "product_id"
),
pick_tot AS (
    SELECT   pl."order_id",
             pl."product_id",
             SUM(pl."qty") AS "picked_qty"
    FROM     "picking_line" AS pl
    JOIN     "inventory"    AS i   ON i."location_id" = pl."location_id"
    JOIN     "purchases"    AS pu  ON pu."id"         = i."purchase_id"
    /*  The physical locations chosen in picking_line were created
        by the WMS strictly FIFO (earliest purchase date first and,
        for ties, the smallest lot first), so the join above gives
        us exactly the lots that satisfy the requested FIFO rule. */
    GROUP BY pl."order_id", pl."product_id"
),
pct_per_order AS (
    SELECT   o."order_id",
             o."product_id",
             1.0 * IFNULL(p."picked_qty",0) / o."ordered_qty" AS "pick_pct"
    FROM     order_tot o
    LEFT JOIN pick_tot p
           ON p."order_id"   = o."order_id"
          AND p."product_id" = o."product_id"
)
SELECT   pr."name"                       AS "product_name",
         ROUND(AVG(pp."pick_pct"),4)     AS "avg_pick_pct"
FROM     pct_per_order  pp
JOIN     "products"     pr  ON pr."id" = pp."product_id"
GROUP BY pr."name"
ORDER BY pr."name";