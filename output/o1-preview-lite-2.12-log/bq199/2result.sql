SELECT
  t.`category_name`,
  ROUND(t.avg_price_2019, 4) AS avg_price_2019,
  ROUND(t.avg_price_2020, 4) AS avg_price_2020,
  ROUND(t.avg_price_2021, 4) AS avg_price_2021
FROM (
  SELECT
    `category_name`,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2019 THEN `sale_dollars` ELSE NULL END) / SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2019 THEN `volume_sold_liters` ELSE NULL END) AS avg_price_2019,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2020 THEN `sale_dollars` ELSE NULL END) / SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2020 THEN `volume_sold_liters` ELSE NULL END) AS avg_price_2020,
    SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2021 THEN `sale_dollars` ELSE NULL END) / SUM(CASE WHEN EXTRACT(YEAR FROM `date`) = 2021 THEN `volume_sold_liters` ELSE NULL END) AS avg_price_2021
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE EXTRACT(YEAR FROM `date`) BETWEEN 2019 AND 2021
  GROUP BY `category_name`
) AS t
ORDER BY t.avg_price_2021 DESC
LIMIT 10;