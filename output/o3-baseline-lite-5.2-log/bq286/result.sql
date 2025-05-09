SELECT name
FROM (
  SELECT
    name,
    SAFE_DIVIDE(SUM(IF(state = 'WY', number, 0)), SUM(number)) AS proportion
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
)
WHERE proportion > 0
ORDER BY proportion DESC, name
LIMIT 1;