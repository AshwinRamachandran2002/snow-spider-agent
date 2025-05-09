WITH fifo AS (
    SELECT  i.id AS inv_id,
            i.product_id,
            i.qty,
            pu.purchased,
            ROW_NUMBER() OVER (
                PARTITION BY i.product_id
                ORDER BY pu.purchased, i.qty
            ) AS rk
    FROM    inventory  i
    JOIN    purchases  pu ON pu.id = i.purchase_id
),
match AS (
    SELECT  ol.id   AS orderline_id,
            ol.product_id,
            ol.qty  AS required_qty,
            MIN(ol.qty, f.qty) AS picked_qty
    FROM    orderlines ol
    JOIN    fifo      f
           ON f.product_id = ol.product_id
          AND f.rk = 1
),
perc AS (
    SELECT  product_id,
            1.0 * picked_qty / required_qty AS pick_pct
    FROM    match
)
SELECT  pr.name                             AS product_name,
        ROUND(AVG(perc.pick_pct), 4)        AS avg_pick_pct
FROM    perc
JOIN    products pr ON pr.id = perc.product_id
GROUP BY pr.name
ORDER BY pr.name;