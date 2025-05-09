WITH avg_price_per_liter_per_category AS (
  SELECT 
    EXTRACT(YEAR FROM "date") AS "year",
    "category_name",
    SUM("sale_dollars") AS "total_sales",
    SUM("volume_sold_liters") AS "total_volume",
    SUM("sale_dollars") / NULLIF(SUM("volume_sold_liters"), 0) AS "avg_price_per_liter"
  FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
  WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
  GROUP BY 
    EXTRACT(YEAR FROM "date"),
    "category_name"
),
top_categories AS (
  SELECT
    "category_name"
  FROM avg_price_per_liter_per_category
  WHERE "year" = 2021
  ORDER BY "avg_price_per_liter" DESC NULLS LAST
  LIMIT 10
)
SELECT 
  t."category_name" AS "Category_Name",
  ROUND(p2019."avg_price_per_liter", 4) AS "Avg_Price_Per_Liter_2019",
  ROUND(p2020."avg_price_per_liter", 4) AS "Avg_Price_Per_Liter_2020",
  ROUND(p2021."avg_price_per_liter", 4) AS "Avg_Price_Per_Liter_2021"
FROM top_categories t
LEFT JOIN avg_price_per_liter_per_category p2019
  ON t."category_name" = p2019."category_name" AND p2019."year" = 2019
LEFT JOIN avg_price_per_liter_per_category p2020
  ON t."category_name" = p2020."category_name" AND p2020."year" = 2020
LEFT JOIN avg_price_per_liter_per_category p2021
  ON t."category_name" = p2021."category_name" AND p2021."year" = 2021
ORDER BY p2021."avg_price_per_liter" DESC NULLS LAST;