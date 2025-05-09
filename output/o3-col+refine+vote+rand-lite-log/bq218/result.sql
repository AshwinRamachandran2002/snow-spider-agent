WITH yearly AS (
  SELECT
    `item_description`,
    EXTRACT(YEAR FROM `date`) AS year,
    SUM(`sale_dollars`)       AS item_sales
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  GROUP BY `item_description`, year
),
paired AS (
  SELECT
    y2023.`item_description`,
    y2022.item_sales AS sales_2022,
    y2023.item_sales AS sales_2023,
    SAFE_DIVIDE(y2023.item_sales - y2022.item_sales,
                y2022.item_sales) * 100 AS yoy_growth_pct
  FROM yearly y2022
  JOIN yearly y2023
    ON  y2022.`item_description` = y2023.`item_description`
   AND y2022.year = 2022
   AND y2023.year = 2023
  WHERE y2022.item_sales > 0               -- exclude zero or negative 2022 sales
)
SELECT
  `item_description`,
  sales_2022,
  sales_2023,
  ROUND(yoy_growth_pct, 4) AS yoy_growth_pct
FROM paired
ORDER BY yoy_growth_pct DESC
LIMIT 5;