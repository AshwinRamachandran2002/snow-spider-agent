WITH dec AS (                      -- stock position at end-Dec-2018
    SELECT
        pm.product_id,
        COALESCE(SUM(i.qty),0) AS start_qty,
        pm.qty_minimum,
        pm.qty_purchase
    FROM   product_minimums pm
    LEFT   JOIN inventory i ON i.product_id = pm.product_id
    GROUP  BY pm.product_id
),
months AS (                        -- the 12 months of 2019
    SELECT 1 seq,'2019-01' mth UNION ALL
    SELECT 2,'2019-02' UNION ALL
    SELECT 3,'2019-03' UNION ALL
    SELECT 4,'2019-04' UNION ALL
    SELECT 5,'2019-05' UNION ALL
    SELECT 6,'2019-06' UNION ALL
    SELECT 7,'2019-07' UNION ALL
    SELECT 8,'2019-08' UNION ALL
    SELECT 9,'2019-09' UNION ALL
    SELECT 10,'2019-10' UNION ALL
    SELECT 11,'2019-11' UNION ALL
    SELECT 12,'2019-12'
),
demand AS (                        -- quantities that leave (sales)
    SELECT
        strftime('%Y-%m',o.ordered) AS mth,
        ol.product_id,
        SUM(ol.qty)                AS sold_qty
    FROM   orderlines ol
    JOIN   orders o ON o.id = ol.order_id
    WHERE  o.ordered >= '2019-01-01'
      AND  o.ordered <  '2020-01-01'
    GROUP  BY ol.product_id, mth
),
supply AS (                        -- quantities that arrive (purchases)
    SELECT
        strftime('%Y-%m',purchased) AS mth,
        product_id,
        SUM(qty)                   AS purch_qty
    FROM   purchases
    WHERE  purchased >= '2019-01-01'
      AND  purchased <  '2020-01-01'
    GROUP  BY product_id, mth
),
sim AS (                            -- recursive month-by-month roll-forward
    SELECT              -- initial state (end-Dec-2018)
        d.product_id,
        0              AS seq,
        '2018-12'      AS mth,
        d.start_qty    AS opening_qty,
        0              AS purchased_in,
        0              AS sold_out,
        d.start_qty    AS ending_qty
    FROM   dec d
    UNION ALL
    SELECT              -- roll one month forward
        s.product_id,
        m.seq,
        m.mth,
        s.ending_qty                                    AS opening_qty,
        IFNULL(sup.purch_qty,0)                         AS purchased_in,
        IFNULL(dem.sold_qty,0)                          AS sold_out,
        CASE                                            -- restock rule
            WHEN (s.ending_qty
                  + IFNULL(sup.purch_qty,0)
                  - IFNULL(dem.sold_qty,0)) < d.qty_minimum
            THEN (s.ending_qty
                  + IFNULL(sup.purch_qty,0)
                  - IFNULL(dem.sold_qty,0))
                 + d.qty_purchase
            ELSE (s.ending_qty
                  + IFNULL(sup.purch_qty,0)
                  - IFNULL(dem.sold_qty,0))
        END                                             AS ending_qty
    FROM   sim     s
    JOIN   months  m   ON m.seq = s.seq + 1
    JOIN   dec     d   ON d.product_id = s.product_id
    LEFT   JOIN supply sup ON sup.product_id = s.product_id AND sup.mth = m.mth
    LEFT   JOIN demand dem ON dem.product_id = s.product_id AND dem.mth = m.mth
),
gap AS (                            -- distance to the minimum each month
    SELECT
        product_id,
        mth,
        ABS(ending_qty - pm.qty_minimum) AS abs_gap
    FROM   sim
    JOIN   product_minimums pm USING (product_id)
    WHERE  mth LIKE '2019-%'
),
ranked AS (                         -- pick the closest month per product
    SELECT
        product_id,
        mth,
        abs_gap,
        ROW_NUMBER() OVER (PARTITION BY product_id
                           ORDER BY abs_gap, mth) AS rn
    FROM   gap
)
SELECT
    product_id,
    mth  AS closest_month_in_2019,
    ROUND(abs_gap,4) AS abs_gap
FROM   ranked
WHERE  rn = 1
ORDER  BY product_id;