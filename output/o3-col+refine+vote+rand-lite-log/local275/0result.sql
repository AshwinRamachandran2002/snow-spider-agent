WITH ratios AS (
    -- seasonality-adjusted ratio for every month (whole history)
    SELECT  product_id,
            mth,
            qty * 1.0 /
            AVG(qty) OVER (
                PARTITION BY product_id
                ORDER BY mth
                ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
            ) AS ratio
    FROM    monthly_sales
),
summary AS (
    -- look at 2017 only: count months and find the worst ratio
    SELECT  product_id,
            SUM(CASE WHEN strftime('%Y', mth) = '2017' THEN 1 ELSE 0 END) AS months_2017,
            MIN(CASE WHEN strftime('%Y', mth) = '2017' THEN ratio END)    AS min_ratio_2017
    FROM    ratios
    GROUP BY product_id
),
winners AS (
    SELECT product_id
    FROM   summary
    WHERE  months_2017 = 12          -- all 12 calendar months present
      AND  min_ratio_2017 > 2        -- ratio above 2 every month
)
-- final output; if none qualify, show an explanatory row
SELECT p.id   AS product_id,
       p.name AS product_name
FROM   products p
JOIN   winners  w ON w.product_id = p.id

UNION ALL
SELECT NULL       AS product_id,
       'No product meets the criteria' AS product_name
WHERE  NOT EXISTS (SELECT 1 FROM winners);