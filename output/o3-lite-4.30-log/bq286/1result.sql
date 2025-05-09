SELECT
  `name`,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN `state` = 'WY' THEN `number` END),
      SUM(`number`)
    ),
    4
  ) AS proportion
FROM `bigquery-public-data.usa_names.usa_1910_current`
WHERE `gender` = 'F'
  AND `year` = 2021
GROUP BY `name`
ORDER BY proportion DESC, `name`
LIMIT 1;