WITH filtered AS (
    SELECT
        DATE_TRUNC('month', "date")             AS month,
        "category_name",
        "sale_dollars"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE())          -- up to the last fully completed month
),
monthly_totals AS (               -- total sales $ each month
    SELECT
        month,
        SUM("sale_dollars")        AS total_sale
    FROM filtered
    GROUP BY month
),
monthly_category AS (             -- sales $ for each category each month
    SELECT
        f.month,
        f."category_name",
        SUM(f."sale_dollars")      AS cat_sale
    FROM filtered f
    GROUP BY f.month, f."category_name"
),
monthly_pct AS (                  -- category share of monthly sales
    SELECT
        mc.month,
        mc."category_name",
        mc.cat_sale / mt.total_sale AS pct
    FROM monthly_category mc
    JOIN monthly_totals mt
      ON mc.month = mt.month
),
qualified_categories AS (         -- categories present ≥24 months & avg ≥1 % share
    SELECT
        "category_name",
        COUNT(*)        AS months_with_data,
        AVG(pct)        AS avg_pct
    FROM monthly_pct
    GROUP BY "category_name"
    HAVING months_with_data >= 24
       AND avg_pct >= 0.01
),
pair_correlations AS (            -- Pearson correlation for every qualified pair
    SELECT
        a."category_name" AS category1,
        b."category_name" AS category2,
        CORR(a.pct, b.pct) AS pearson_corr
    FROM monthly_pct a
    JOIN monthly_pct b
      ON a.month = b.month
    JOIN qualified_categories q1
      ON a."category_name" = q1."category_name"
    JOIN qualified_categories q2
      ON b."category_name" = q2."category_name"
    WHERE a."category_name" < b."category_name"          -- avoid duplicate pairs & self‑joins
    GROUP BY category1, category2
)
SELECT
    category1  AS category_name_1,
    category2  AS category_name_2
FROM pair_correlations
ORDER BY pearson_corr ASC NULLS LAST, category1, category2
LIMIT 1;