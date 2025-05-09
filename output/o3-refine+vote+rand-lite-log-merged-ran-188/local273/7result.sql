WITH
/* --- 1.  FIFO quantity for every product ------------------------------- */
earliest AS (
    SELECT i.product_id,
           MIN(pu.purchased) AS first_purchase
    FROM   inventory  AS i
    JOIN   purchases  AS pu ON pu.id = i.purchase_id
    GROUP  BY i.product_id
),
fifo AS (
    /* among the rows that belong to the very first purchase,
       keep the smallest (available) quantity                       */
    SELECT i.product_id,
           MIN(i.qty) AS fifo_qty
    FROM   inventory AS i
    JOIN   purchases AS pu ON pu.id = i.purchase_id
    JOIN   earliest  AS e  ON e.product_id   = i.product_id
                          AND e.first_purchase = pu.purchased
    GROUP  BY i.product_id
),

/* --- 2.  Ordered and picked quantities per order / product ------------ */
ord AS (
    SELECT order_id,
           product_id,
           SUM(qty) AS order_qty
    FROM   orderlines
    GROUP  BY order_id, product_id
),
pik AS (
    SELECT order_id,
           product_id,
           SUM(qty) AS picked_qty
    FROM   picking_line
    GROUP  BY order_id, product_id
),

/* --- 3.  Pick-percentage per order line, limited by FIFO stock -------- */
pct AS (
    SELECT  ord.product_id,
            1.0 *
            /* effective picked = overlap(order, picked, fifo) */
            MIN( MIN(fifo.fifo_qty, pik.picked_qty), ord.order_qty )
            / ord.order_qty           AS pick_pct
    FROM    ord
    JOIN    pik  ON pik.order_id   = ord.order_id
                AND pik.product_id = ord.product_id
    JOIN    fifo ON fifo.product_id = ord.product_id
)

/* --- 4.  Average pick-percentage per product name --------------------- */
SELECT  pr.name                         AS product_name,
        ROUND( AVG(pct.pick_pct), 4 )   AS avg_pick_percentage
FROM    pct
JOIN    products AS pr ON pr.id = pct.product_id
GROUP   BY pr.name
ORDER   BY pr.name;