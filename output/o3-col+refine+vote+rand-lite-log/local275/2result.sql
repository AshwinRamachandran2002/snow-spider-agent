WITH cma AS (                             -- 12-month centred moving average
    SELECT
        ms.product_id,
        ms.mth,
        ms.qty,
        AVG(ms.qty) OVER (
            PARTITION BY ms.product_id
            ORDER BY ms.mth
            ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING
        ) AS cma
    FROM monthly_sales AS ms
),
ratio_2017 AS (                           -- seasonality-adjusted ratio for 2017
    SELECT
        product_id,
        mth,
        qty / cma AS ratio
    FROM cma
    WHERE substr(mth,1,4) = '2017'
      AND cma IS NOT NULL
),
tally AS (                                -- months present vs. months with ratio > 2
    SELECT
        product_id,
        COUNT(*)                                   AS months_2017,
        SUM(CASE WHEN ratio > 2 THEN 1 END)       AS months_above_2
    FROM ratio_2017
    GROUP BY product_id
),
qualified AS (                            -- products above threshold all 12 months
    SELECT
        p.id   AS product_id,
        p.name AS product_name
    FROM tally AS t
    JOIN products AS p ON p.id = t.product_id
    WHERE t.months_2017  = 12
      AND t.months_above_2 = 12
)
SELECT product_id,
       product_name
FROM qualified
UNION ALL                   -- return 'None' row if no product qualifies
SELECT NULL,
       'None'
WHERE NOT EXISTS (SELECT 1 FROM qualified)
ORDER BY 1;