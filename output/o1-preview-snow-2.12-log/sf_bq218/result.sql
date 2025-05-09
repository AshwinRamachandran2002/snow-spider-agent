SELECT
  "item_description",
  ROUND(((total_sales_2023 - total_sales_2022) / total_sales_2022) * 100, 4) AS "Growth_Percentage"
FROM (
  SELECT
    "item_description",
    SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2023 THEN "sale_dollars" ELSE 0 END) AS total_sales_2023,
    SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2022 THEN "sale_dollars" ELSE 0 END) AS total_sales_2022
  FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
  GROUP BY "item_description"
) subquery
WHERE total_sales_2022 > 0
ORDER BY "Growth_Percentage" DESC NULLS LAST
LIMIT 5;