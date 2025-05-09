SELECT
  `start_station_id` AS station_id,
  ROUND(SUM(CASE WHEN `start_station_id` = `end_station_id` AND `tripduration` <= 120 THEN 1 ELSE 0 END) / COUNT(*), 4) AS proportion
FROM `bigquery-public-data.new_york.citibike_trips`
GROUP BY `start_station_id`
ORDER BY proportion DESC
LIMIT 10;