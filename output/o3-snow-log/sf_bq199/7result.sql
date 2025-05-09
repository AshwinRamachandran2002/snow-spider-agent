WITH per_row AS (   -- 1.  Per-transaction per-liter retail price for 2019-2021
    SELECT
        "category_name",
        YEAR("date")                           AS sales_year,
        "state_bottle_retail" / ("bottle_volume_ml" / 1000.0)  AS per_liter_retail_price
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2019-01-01'
      AND "date" <  '2022-01-01'
      AND "state_bottle_retail" IS NOT NULL
      AND "bottle_volume_ml"   > 0
      AND "category_name"      IS NOT NULL
),  

category_year_avg AS (   -- 2.  Average per-liter price by category & year
    SELECT
        "category_name",
        sales_year,
        AVG(per_liter_retail_price) AS avg_per_liter_price
    FROM per_row
    GROUP BY "category_name", sales_year
),  

top_categories_2021 AS (  -- 3.  Top 10 categories by 2021 average per-liter price
    SELECT
        "category_name"
    FROM category_year_avg
    WHERE sales_year = 2021
    ORDER BY avg_per_liter_price DESC NULLS LAST
    LIMIT 10
)

-- 4.  Return 2019-2021 averages for the top 2021 categories
SELECT
    c."category_name",
    ROUND(MAX(CASE WHEN sales_year = 2019 THEN avg_per_liter_price END), 4) AS avg_price_2019,
    ROUND(MAX(CASE WHEN sales_year = 2020 THEN avg_per_liter_price END), 4) AS avg_price_2020,
    ROUND(MAX(CASE WHEN sales_year = 2021 THEN avg_per_liter_price END), 4) AS avg_price_2021
FROM category_year_avg c
JOIN top_categories_2021 t
  ON c."category_name" = t."category_name"
GROUP BY c."category_name"
ORDER BY avg_price_2021 DESC NULLS LAST;