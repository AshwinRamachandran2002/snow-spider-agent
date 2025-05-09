WITH
-- all months of interest in 2019
months(month) AS (
    SELECT '2019-01-01'
    UNION ALL
    SELECT DATE(month,'+1 month')
    FROM   months
    WHERE  month<'2019-12-01'
),

-- inventory position we start out with (end‑of December 2018 = opening of 2019)
initial_stock AS (
    SELECT product_id,
           COALESCE(SUM(qty),0) AS qty_init
    FROM   inventory
    GROUP  BY product_id
),

-- the products that carry a min / purchase rule
products AS (
    SELECT pm.product_id,
           COALESCE(isn.qty_init,0) AS qty_init,
           pm.qty_minimum,
           pm.qty_purchase
    FROM   product_minimums pm
    LEFT   JOIN initial_stock isn ON isn.product_id = pm.product_id
),

-- quantities bought during 2019 (incoming)
month_purchases AS (
    SELECT product_id,
           DATE(SUBSTR(purchased,1,7)||'-01') AS month,
           SUM(qty)                          AS qty_in
    FROM   purchases
    WHERE  purchased BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP  BY product_id, month
),

-- quantities sold during 2019 (outgoing)
month_sales AS (
    SELECT ol.product_id,
           DATE(SUBSTR(o.ordered,1,7)||'-01') AS month,
           SUM(ol.qty)                        AS qty_out
    FROM   orderlines  ol
    JOIN   orders      o  ON o.id = ol.order_id
    WHERE  o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP  BY ol.product_id, month
),

-- recursive month‑by‑month inventory calculation
inv_chain AS (
    -- seed row : fictitious month 2018‑12 showing starting quantity
    SELECT p.product_id,
           '2018-12-01'      AS month,
           p.qty_init        AS ending_qty          -- the number we carry forward
    FROM   products p

    UNION ALL
    
    -- every following month of 2019
    SELECT
           ic.product_id,
           m.month,
           CASE
               WHEN (ic.ending_qty
                     + COALESCE(mp.qty_in,0)
                     - COALESCE(ms.qty_out,0)) < p.qty_minimum
               THEN (ic.ending_qty
                     + COALESCE(mp.qty_in,0)
                     - COALESCE(ms.qty_out,0))
                    + p.qty_purchase                -- restock once
               ELSE (ic.ending_qty
                     + COALESCE(mp.qty_in,0)
                     - COALESCE(ms.qty_out,0))
           END                                       AS ending_qty
    FROM   inv_chain        ic
    JOIN   months           m   ON m.month = DATE(ic.month,'+1 month')
    JOIN   products         p   ON p.product_id = ic.product_id
    LEFT   JOIN month_purchases mp ON mp.product_id = ic.product_id
                                   AND mp.month     = m.month
    LEFT   JOIN month_sales     ms ON ms.product_id = ic.product_id
                                   AND ms.month     = m.month
),

-- absolute deviation from the minimum for each month in 2019
month_diffs AS (
    SELECT ic.product_id,
           ic.month,
           ABS(ic.ending_qty - p.qty_minimum) AS diff
    FROM   inv_chain ic
    JOIN   products  p  USING (product_id)
    WHERE  ic.month BETWEEN '2019-01-01' AND '2019-12-01'
),

-- pick the month with the smallest deviation (earliest month wins if tied)
ranked AS (
    SELECT product_id,
           month,
           diff,
           ROW_NUMBER() OVER (PARTITION BY product_id
                              ORDER BY diff, month) AS rn
    FROM   month_diffs
)

SELECT product_id,
       month,
       diff
FROM   ranked
WHERE  rn = 1
ORDER  BY product_id;