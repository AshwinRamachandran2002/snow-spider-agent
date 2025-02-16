-- Task: For each item, list the total sales revenue in 2022 and 2023. Limit the results to the first 100 items.
SELECT
  "item_description",
  SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2023 THEN "sale_dollars" ELSE 0 END) AS total_sales_2023,
  SUM(CASE WHEN EXTRACT(YEAR FROM "date") = 2022 THEN "sale_dollars" ELSE 0 END) AS total_sales_2022
FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
GROUP BY "item_description"
LIMIT 100;