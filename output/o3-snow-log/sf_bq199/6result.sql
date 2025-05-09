/*-----------------------------------------------------------------------------------------------------------------
  Purpose   : 1) Identify the 10 liquor categories whose average per-liter retail price was highest in 2021.
              2) For those same categories, return their average per-liter retail prices for 2019, 2020 and 2021.
              
  Definition: Per-liter retail price for one sales record = STATE_BOTTLE_RETAIL / (BOTTLE_VOLUME_ML / 1000)
              i.e. STATE_BOTTLE_RETAIL * 1000 / BOTTLE_VOLUME_ML
-----------------------------------------------------------------------------------------------------------------*/

WITH per_category_year AS (   -- average price per category per calendar year
    SELECT
        "category_name",
        YEAR("date")                                          AS sale_year,
        AVG( "state_bottle_retail" * 1000
             / NULLIF("bottle_volume_ml",0) )                 AS avg_per_liter_retail_price
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE YEAR("date") IN (2019, 2020, 2021)                  -- years of interest
      AND "category_name"      IS NOT NULL
      AND "state_bottle_retail" IS NOT NULL
      AND "bottle_volume_ml"    IS NOT NULL
    GROUP BY "category_name", YEAR("date")
),

top10_2021 AS (            -- pick 10 categories with highest 2021 average price
    SELECT
        "category_name"
    FROM per_category_year
    WHERE sale_year = 2021
    ORDER BY avg_per_liter_retail_price DESC NULLS LAST
    LIMIT 10
)

SELECT
    c."category_name",
    ROUND( MAX(CASE WHEN c.sale_year = 2019 THEN c.avg_per_liter_retail_price END), 4) AS avg_per_liter_2019,
    ROUND( MAX(CASE WHEN c.sale_year = 2020 THEN c.avg_per_liter_retail_price END), 4) AS avg_per_liter_2020,
    ROUND( MAX(CASE WHEN c.sale_year = 2021 THEN c.avg_per_liter_retail_price END), 4) AS avg_per_liter_2021
FROM   per_category_year  c
JOIN   top10_2021         t  ON c."category_name" = t."category_name"
GROUP  BY c."category_name"
ORDER  BY avg_per_liter_2021 DESC NULLS LAST;