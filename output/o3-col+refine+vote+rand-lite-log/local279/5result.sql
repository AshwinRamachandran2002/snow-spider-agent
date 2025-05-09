WITH RECURSIVE
/* 1. Calendar from 2018-12-01 to 2019-12-01 (inclusive) */
months(mth) AS (
    SELECT DATE('2018-12-01')
    UNION ALL
    SELECT DATE(mth,'+1 month') FROM months WHERE mth<'2019-12-01'
),

/* 2. Opening stock = on-hand qty as of 2018-12-31 */
start_stock AS (
    SELECT product_id,
           SUM(qty) AS start_qty
    FROM   inventory
    GROUP  BY product_id
),

/* 3. Incoming / outgoing movements per product & month during 2019 */
in_out AS (
    SELECT  m.mth,
            p.product_id,
            COALESCE(ins.qty_in ,0) AS qty_in,
            COALESCE(outs.qty_out,0) AS qty_out
    FROM        months AS m
    CROSS JOIN  start_stock AS p
    LEFT JOIN (
        SELECT  product_id,
                DATE(STRFTIME('%Y-%m-01', purchased)) AS mth,
                SUM(qty) AS qty_in
        FROM    purchases
        WHERE   purchased BETWEEN '2019-01-01' AND '2019-12-31'
        GROUP   BY product_id, DATE(STRFTIME('%Y-%m-01', purchased))
    ) AS ins  ON ins.product_id = p.product_id AND ins.mth = m.mth
    LEFT JOIN (
        SELECT  ol.product_id,
                DATE(STRFTIME('%Y-%m-01', o.ordered)) AS mth,
                SUM(ol.qty) AS qty_out
        FROM    orderlines AS ol
        JOIN    orders     AS o ON o.id = ol.order_id
        WHERE   o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
        GROUP   BY ol.product_id, DATE(STRFTIME('%Y-%m-01', o.ordered))
    ) AS outs ON outs.product_id = p.product_id AND outs.mth = m.mth
),

/* 4. Minimum level and standard purchase lot per product */
mins AS (
    SELECT product_id,
           qty_minimum,
           qty_purchase
    FROM   product_minimums
),

/* 5. Recursive month-by-month inventory roll-forward with conditional restock */
inv(product_id, mth, end_qty) AS (
    /* seed row = December-2018 closing balance */
    SELECT  s.product_id,
            DATE('2018-12-01'),
            s.start_qty
    FROM    start_stock AS s
    
    UNION ALL
    
    SELECT  io.product_id,
            io.mth,
            CASE
                WHEN prev.end_qty + io.qty_in - io.qty_out
                     < COALESCE(mn.qty_minimum, -1e9)
                THEN prev.end_qty + io.qty_in - io.qty_out
                     + COALESCE(mn.qty_purchase,0)
                ELSE prev.end_qty + io.qty_in - io.qty_out
            END
    FROM        inv      AS prev
    JOIN        in_out   AS io
           ON   io.product_id = prev.product_id
          AND   io.mth = DATE(prev.mth,'+1 month')
    LEFT JOIN   mins     AS mn
           ON   mn.product_id = prev.product_id
),

/* 6. Absolute gap between month-end inventory and the minimum level */
gaps AS (
    SELECT  i.product_id,
            i.mth,
            ABS(i.end_qty - mn.qty_minimum) AS gap_to_min
    FROM    inv AS i
    JOIN    mins AS mn USING (product_id)
    WHERE   i.mth BETWEEN '2019-01-01' AND '2019-12-01'
),

/* 7. Rank months per product by smallest gap (earliest tie-breaker) */
ranked AS (
    SELECT  g.*,
            ROW_NUMBER() OVER (
                PARTITION BY g.product_id
                ORDER BY g.gap_to_min, g.mth
            ) AS rn
    FROM    gaps AS g
)

/* 8. Final result */
SELECT  product_id,
        mth  AS month,
        gap_to_min AS abs_difference_to_minimum
FROM    ranked
WHERE   rn = 1
ORDER   BY product_id;