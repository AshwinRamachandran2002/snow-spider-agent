WITH inventory_tot AS (                   -- total on‑hand for every product
    SELECT
        "product_id",
        SUM("qty") AS tot_qty
    FROM "inventory"
    GROUP BY "product_id"
),
order_need AS (                           -- what every order line asks for
    SELECT
        ol."id"         AS orderline_id,
        ol."product_id",
        ol."qty"        AS need_qty,
        COALESCE(it.tot_qty,0) AS avail_qty
    FROM "orderlines"  ol
    LEFT JOIN inventory_tot it
           ON it."product_id" = ol."product_id"
),
picked AS (                               -- qty that can actually be picked
    SELECT
        orderline_id,
        "product_id",
        CASE                                     -- overlap between need & stock
             WHEN need_qty <= avail_qty THEN need_qty
             ELSE avail_qty
        END                 AS picked_qty,
        need_qty
    FROM order_need
),
pick_pct AS (                             -- pick‑percentage per order line
    SELECT
        "product_id",
        CAST(picked_qty AS REAL) / need_qty AS pct
    FROM picked
)
SELECT
    pr."name"                                  AS product_name,
    ROUND(AVG(pct)*100,4)                      AS avg_pick_percentage
FROM pick_pct pp
JOIN "products" pr
     ON pr."id" = pp."product_id"
GROUP BY pr."name"
ORDER BY pr."name";