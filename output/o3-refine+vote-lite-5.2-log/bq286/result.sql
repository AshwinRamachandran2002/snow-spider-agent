SELECT wy.name
FROM (
  SELECT name, SUM(number) AS wy_count
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY'
    AND gender = 'F'
    AND year = 2021
  GROUP BY name
) AS wy
JOIN (
  SELECT name, SUM(number) AS total_count
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
) AS tot
ON wy.name = tot.name
ORDER BY wy.wy_count / tot.total_count DESC, wy.name
LIMIT 1;