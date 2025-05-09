WITH wy AS (
  SELECT `name`,
         `number` AS wy_2021_f
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE `year` = 2021
    AND `gender` = 'F'
    AND `state` = 'WY'
),
us AS (
  SELECT `name`,
         SUM(`number`) AS us_2021_f
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE `year` = 2021
    AND `gender` = 'F'
  GROUP BY `name`
)
SELECT wy.`name`
FROM wy
JOIN us USING (`name`)
ORDER BY SAFE_DIVIDE(wy.wy_2021_f, us.us_2021_f) DESC
LIMIT 1;