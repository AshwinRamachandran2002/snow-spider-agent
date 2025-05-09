SELECT wy.name
FROM (
  SELECT name, number AS wy_count
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY' 
    AND gender = 'F' 
    AND year = 2021
) AS wy
JOIN (
  SELECT name, SUM(number) AS total_us_count
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F' 
    AND year = 2021
  GROUP BY name
) AS us
ON wy.name = us.name
ORDER BY SAFE_DIVIDE(wy.wy_count, us.total_us_count) DESC
LIMIT 1;