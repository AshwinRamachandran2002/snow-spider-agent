SELECT wy.`name`
FROM (
  SELECT `name`, SUM(`number`) AS total_in_wyoming
  FROM `bigquery-public-data`.usa_names.usa_1910_current
  WHERE `state` = 'WY' AND `gender` = 'F' AND `year` = 2021
  GROUP BY `name`
) AS wy
JOIN (
  SELECT `name`, SUM(`number`) AS total_in_us
  FROM `bigquery-public-data`.usa_names.usa_1910_current
  WHERE `gender` = 'F' AND `year` = 2021
  GROUP BY `name`
) AS us ON wy.`name` = us.`name`
ORDER BY wy.total_in_wyoming / us.total_in_us DESC
LIMIT 1;