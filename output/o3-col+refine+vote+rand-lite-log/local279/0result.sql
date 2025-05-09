WITH RECURSIVE
-- calendar for every month in 2019
months(mth) AS (
    SELECT '2019-01-01'
    UNION ALL
    SELECT date(mth,'+1 month') FROM months WHERE mth < '2019-12-01'
),

-- minimum rules + starting inventory (on-hand as of 31-Dec-2018)
start_inv AS (
    SELECT  pm.product_id,
            pm.qty_minimum,
            pm.qty_purchase,
            COALESCE(SUM(i.qty),0) AS start_qty
    FROM    product_minimums pm
    LEFT    JOIN inventory  i ON i.product_id = pm.product_id
    LEFT    JOIN purchases  p ON p.id = i.purchase_id
                             AND p.purchased <= '2018-12-31'
    GROUP BY pm.product_id
),

-- 2019 sales per product / month
sales AS (
    SELECT  ol.product_id,
            substr(o.ordered,1,7)||'-01' AS mth,
            SUM(ol.qty)                 AS sold
    FROM    orderlines ol
    JOIN    orders o ON o.id = ol.order_id
    WHERE   o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY ol.product_id, substr(o.ordered,1,7)
),

-- recursive inventory model (opening balance each month)
state(product_id, qty_minimum, qty_purchase, mth, begin_inv, sold_qty) AS (
    -- January seed
    SELECT  si.product_id,
            si.qty_minimum,
            si.qty_purchase,
            '2019-01-01',
            si.start_qty,
            COALESCE(s.sold,0)
    FROM    start_inv si
    LEFT    JOIN sales s
           ON s.product_id = si.product_id
          AND s.mth        = '2019-01-01'

    UNION ALL

    -- February .. December
    SELECT  st.product_id,
            st.qty_minimum,
            st.qty_purchase,
            date(st.mth,'+1 month'),
            CASE
                 WHEN st.begin_inv - st.sold_qty < st.qty_minimum
                 THEN st.begin_inv - st.sold_qty + st.qty_purchase
                 ELSE st.begin_inv - st.sold_qty
            END,
            COALESCE(s2.sold,0)
    FROM    state st
    JOIN    months m         ON m.mth = date(st.mth,'+1 month')
    LEFT    JOIN sales  s2   ON s2.product_id = st.product_id
                            AND s2.mth        = m.mth
    WHERE   st.mth < '2019-12-01'
),

-- ending inventory for every month
ending AS (
    SELECT  product_id,
            mth,
            begin_inv - sold_qty        AS end_inv,
            qty_minimum
    FROM    state
),

-- rank months by how close they get to the minimum
ranked AS (
    SELECT  product_id,
            mth,
            ABS(end_inv - qty_minimum)  AS abs_diff,
            ROW_NUMBER() OVER (PARTITION BY product_id
                               ORDER BY ABS(end_inv - qty_minimum),
                                        mth) AS rn
    FROM    ending
)

-- final answer
SELECT  product_id,
        mth  AS month_with_smallest_gap,
        abs_diff
FROM    ranked
WHERE   rn = 1
ORDER BY product_id;