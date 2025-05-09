WITH
-- minimum‑stock settings
minu AS (
    SELECT "product_id",
           "qty_minimum",
           "qty_purchase"
    FROM   "product_minimums"
),

-- inventory on hand as of 2018‑12‑31
start_inv AS (
    SELECT i."product_id",
           SUM(i."qty") AS start_qty
    FROM   "inventory" i
    JOIN   "purchases" p  ON p."id" = i."purchase_id"
    WHERE  DATE(p."purchased") <= '2018-12-31'
    GROUP  BY i."product_id"
),

-- 2019 sales (negative stock movements)
sales AS (
    SELECT ol."product_id",
           SUBSTR(o."ordered",1,7) || '-01' AS mth,
           SUM(ol."qty") AS sold
    FROM   "orderlines" ol
    JOIN   "orders"     o ON o."id" = ol."order_id"
    WHERE  DATE(o."ordered") BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP  BY ol."product_id", mth
),

/* ---------- month‑by‑month inventory, incl. restock when below minimum ---------- */
initial AS (          -- first month (2019‑01)
    SELECT m."product_id",
           '2019-01-01' AS mth,
           CASE
             WHEN (COALESCE(s.start_qty,0) - COALESCE(sa.sold,0)) < m."qty_minimum"
                  THEN (COALESCE(s.start_qty,0) - COALESCE(sa.sold,0)) + m."qty_purchase"
             ELSE (COALESCE(s.start_qty,0) - COALESCE(sa.sold,0))
           END AS end_qty
    FROM   minu  m
    LEFT   JOIN start_inv s ON s."product_id" = m."product_id"
    LEFT   JOIN sales     sa ON sa."product_id" = m."product_id"
                             AND sa.mth = '2019-01-01'
),

inv AS (
    SELECT * FROM initial
    UNION ALL
    SELECT
           inv."product_id",
           DATE(inv.mth,'start of month','+1 month') AS mth,
           CASE
             WHEN (inv.end_qty - COALESCE(sa.sold,0)) < m."qty_minimum"
                  THEN (inv.end_qty - COALESCE(sa.sold,0)) + m."qty_purchase"
             ELSE (inv.end_qty - COALESCE(sa.sold,0))
           END AS end_qty
    FROM   inv
    JOIN   minu   m ON m."product_id" = inv."product_id"
    LEFT   JOIN   sales  sa
           ON  sa."product_id" = inv."product_id"
           AND sa.mth          = DATE(inv.mth,'start of month','+1 month')
    WHERE  inv.mth < '2019-12-01'              -- stop after Dec‑2019
),

/* ---------- find month with smallest gap to minimum ---------- */
best AS (
    SELECT
           inv."product_id",
           inv.mth,
           ABS(inv.end_qty - m."qty_minimum") AS abs_gap,
           ROW_NUMBER() OVER (PARTITION BY inv."product_id"
                              ORDER BY ABS(inv.end_qty - m."qty_minimum"), inv.mth) AS rn
    FROM   inv
    JOIN   minu m ON m."product_id" = inv."product_id"
)

SELECT "product_id",
       mth,
       abs_gap
FROM   best
WHERE  rn = 1                 -- keep the month with the smallest absolute gap
ORDER  BY "product_id";