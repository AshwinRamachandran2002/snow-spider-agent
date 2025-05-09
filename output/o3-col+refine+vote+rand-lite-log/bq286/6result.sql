-- Name with the highest Wyoming-to-nation proportion for female babies in 2021
SELECT name
FROM (
  SELECT
    name,
    SAFE_DIVIDE(
      SUM(IF(state = 'WY', number, 0)),   -- Wyoming count per name
      SUM(number)                         -- National count per name
    ) AS wy_proportion
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
)
ORDER BY wy_proportion DESC
LIMIT 1;