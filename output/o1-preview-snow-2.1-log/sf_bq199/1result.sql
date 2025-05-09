SELECT
  "category_name" AS "Category_Name",
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2019 THEN "sale_dollars" END) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2019 THEN "volume_sold_liters" END), 0), 4) AS "Avg_Price_Per_Liter_2019",
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2020 THEN "sale_dollars" END) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2020 THEN "volume_sold_liters" END), 0), 4) AS "Avg_Price_Per_Liter_2020",
  ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2021 THEN "sale_dollars" END) / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2021 THEN "volume_sold_liters" END), 0), 4) AS "Avg_Price_Per_Liter_2021"
FROM
  IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
GROUP BY
  "category_name"
HAVING
  SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2019 THEN "volume_sold_liters" END) > 0
  AND SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2020 THEN "volume_sold_liters" END) > 0
  AND SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2021 THEN "volume_sold_liters" END) > 0
ORDER BY
  "Avg_Price_Per_Liter_2021" DESC NULLS LAST
LIMIT 10;