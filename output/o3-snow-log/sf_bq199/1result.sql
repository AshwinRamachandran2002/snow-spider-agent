WITH per_txn AS (          -- per–transaction $/liter for 2019-2021
    SELECT
        "category_name",
        EXTRACT(year FROM "date")                          AS sales_year,
        "state_bottle_retail" / ("bottle_volume_ml" / 1000.0) AS price_per_liter
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
      AND "state_bottle_retail" IS NOT NULL
      AND "bottle_volume_ml"   IS NOT NULL
      AND "bottle_volume_ml"  > 0
),

avg_by_cat_year AS (       -- average $/liter for every category & year
    SELECT
        "category_name",
        sales_year,
        AVG(price_per_liter) AS avg_price_per_liter
    FROM per_txn
    GROUP BY "category_name", sales_year
),

top10_2021 AS (            -- top-10 categories by 2021 average $/liter
    SELECT "category_name"
    FROM   avg_by_cat_year
    WHERE  sales_year = 2021
    ORDER  BY avg_price_per_liter DESC NULLS LAST
    LIMIT  10
)

SELECT
    a."category_name",
    ROUND(MAX(CASE WHEN a.sales_year = 2019 THEN a.avg_price_per_liter END),4) AS avg_per_liter_2019,
    ROUND(MAX(CASE WHEN a.sales_year = 2020 THEN a.avg_price_per_liter END),4) AS avg_per_liter_2020,
    ROUND(MAX(CASE WHEN a.sales_year = 2021 THEN a.avg_price_per_liter END),4) AS avg_per_liter_2021
FROM  avg_by_cat_year a
JOIN  top10_2021      t ON a."category_name" = t."category_name"
GROUP BY a."category_name"
ORDER BY avg_per_liter_2021 DESC NULLS LAST;