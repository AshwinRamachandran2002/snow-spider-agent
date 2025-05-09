WITH seasonality AS (
    SELECT
        ms.product_id,
        ms.mth,
        ms.qty,
        AVG(ms.qty) OVER (
            PARTITION BY ms.product_id
            ORDER BY ms.mth
            ROWS BETWEEN 6 PRECEDING AND 6 FOLLOWING
        ) AS mov_avg_13m
    FROM monthly_sales AS ms
),
ratio_2017 AS (
    SELECT
        product_id,
        mth,
        qty * 1.0 / mov_avg_13m AS ratio
    FROM seasonality
    WHERE mth BETWEEN '2017-01-01' AND '2017-12-31'
),
qualified AS (
    SELECT
        p.id   AS product_id,
        p.name AS product_name
    FROM products AS p
    JOIN (
        SELECT product_id
        FROM ratio_2017
        GROUP BY product_id
        HAVING COUNT(*) = 12       -- all 12 months present
           AND MIN(ratio) > 2      -- ratio above 2 every month
    ) AS q
    ON q.product_id = p.id
)
SELECT product_id, product_name
FROM qualified

UNION ALL                 -- return a placeholder row if none qualify
SELECT NULL AS product_id, 'None qualify' AS product_name
WHERE NOT EXISTS (SELECT 1 FROM qualified);