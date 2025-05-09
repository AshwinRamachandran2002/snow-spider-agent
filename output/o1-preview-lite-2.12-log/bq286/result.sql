SELECT wy.name
FROM (
  SELECT name, SUM(number) AS wyoming_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY' AND gender = 'F' AND year = 2021
  GROUP BY name
) AS wy
JOIN (
  SELECT name, SUM(number) AS national_total
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F' AND year = 2021
  GROUP BY name
) AS us
ON wy.name = us.name
ORDER BY (CAST(wy.wyoming_total AS FLOAT64) / us.national_total) DESC
LIMIT 1;