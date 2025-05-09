WITH sales AS (                                       -- 1. sales from Jan‑2016 forward
    SELECT
        product_id,
        date(mth)                          AS mth,
        CAST(strftime('%Y',mth) AS INT)    AS yr,
        CAST(strftime('%m',mth) AS INT)    AS mn,
        qty
    FROM monthly_sales
    WHERE date(mth) >= '2016-01-01'
),
-- 2. 12‑month centred moving average (6 months before and after)
cma AS (
    SELECT
        product_id,
        mth, yr, mn, qty,
        AVG(qty) OVER (
            PARTITION BY product_id
            ORDER BY mth
            ROWS BETWEEN 6 PRECEDING AND 6 FOLLOWING
        ) AS cma
    FROM sales
    WHERE qty IS NOT NULL
),
-- 3. ratio (actual / CMA) – basis for seasonal indices
ratio AS (
    SELECT
        product_id,
        yr, mn,
        qty,
        cma,
        qty * 1.0 / cma                    AS ratio_cma
    FROM cma
    WHERE cma IS NOT NULL
),
-- 4. seasonal index for each product & month‑of‑year
seasonal_idx AS (
    SELECT
        product_id,
        mn,
        AVG(ratio_cma) AS idx              -- average ratio for that month (exclude 2017)
    FROM ratio
    WHERE yr <> 2017
    GROUP BY product_id, mn
    HAVING idx <> 0
),
-- 5. seasonally‑adjusted sales for 2017 (actual / seasonal index)
adjusted17 AS (
    SELECT
        r.product_id,
        r.mn,
        r.qty  / si.idx    AS adj_qty
    FROM ratio        r
    JOIN seasonal_idx si
         ON si.product_id = r.product_id
        AND si.mn         = r.mn
    WHERE r.yr = 2017
),
-- 6. products whose adjusted sales stay above 2 for every month of 2017
qualified AS (
    SELECT  product_id
    FROM    adjusted17
    GROUP BY product_id
    HAVING  COUNT(*) = 12          -- all 12 months present
       AND  MIN(adj_qty) > 2       -- consistently above 2
)
SELECT p.id,
       p.name
FROM   qualified q
JOIN   products  p ON p.id = q.product_id
ORDER BY p.id;