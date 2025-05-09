WITH monthly_volumes AS (   -- total liters per category per month
    SELECT
        DATE_TRUNC('MONTH', "date")        AS sales_month,
        "category_name",
        SUM("volume_sold_liters")          AS liters
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01'
      AND DATE_TRUNC('MONTH', "date") < DATE_TRUNC('MONTH', CURRENT_DATE)   -- through last full month
    GROUP BY sales_month, "category_name"
),
month_totals AS (           -- overall liters each month
    SELECT
        sales_month,
        SUM(liters) AS tot_liters
    FROM monthly_volumes
    GROUP BY sales_month
),
cat_month_pct AS (          -- category’s share of monthly volume
    SELECT
        mv.sales_month,
        mv."category_name",
        mv.liters / mt.tot_liters AS pct_of_month
    FROM monthly_volumes mv
    JOIN month_totals  mt  ON mv.sales_month = mt.sales_month
),
qualified AS (              -- keep cats seen ≥24 months & avg share ≥1 %
    SELECT *
    FROM cat_month_pct
    QUALIFY COUNT(*) OVER (PARTITION BY "category_name") >= 24
       AND AVG(pct_of_month) OVER (PARTITION BY "category_name") >= 0.01
),
pair_corr AS (              -- Pearson correlation for each pair of categories
    SELECT
        a."category_name"                           AS category_1,
        b."category_name"                           AS category_2,
        CORR(a.pct_of_month, b.pct_of_month)        AS pearson_correlation
    FROM qualified a
    JOIN qualified b
      ON a.sales_month = b.sales_month
     AND a."category_name" < b."category_name"      -- unique unordered pairs
    GROUP BY category_1, category_2
)
SELECT
    category_1,
    category_2,
    ROUND(pearson_correlation, 4) AS pearson_correlation
FROM pair_corr
ORDER BY pearson_correlation ASC
LIMIT 1;