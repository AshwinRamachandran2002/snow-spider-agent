WITH centred AS (
    SELECT a.product_id,
           a.mth,
           a.qty,
           (SELECT AVG(b.qty)
            FROM monthly_sales b
            WHERE b.product_id = a.product_id
              AND ABS( (CAST(strftime('%Y',b.mth) AS INTEGER) -
                        CAST(strftime('%Y',a.mth) AS INTEGER))*12 +
                        (CAST(strftime('%m',b.mth) AS INTEGER) -
                        CAST(strftime('%m',a.mth) AS INTEGER)) ) <= 6
           ) AS centred_ma
    FROM monthly_sales a
),
ratio_2017 AS (
    SELECT product_id,
           mth,
           qty / centred_ma AS seasonality_ratio
    FROM centred
    WHERE centred_ma IS NOT NULL
      AND strftime('%Y', mth) = '2017'
),
qualifying_products AS (
    SELECT product_id
    FROM ratio_2017
    GROUP BY product_id
    HAVING COUNT(DISTINCT mth) = 12      -- have data for each month of 2017
       AND MIN(seasonality_ratio) > 2    -- ratio stays strictly above 2
)
-- return qualifying product ids; if none qualify, return a single NULL row
SELECT product_id
FROM qualifying_products
UNION ALL
SELECT NULL
WHERE NOT EXISTS (SELECT 1 FROM qualifying_products)
ORDER BY product_id;