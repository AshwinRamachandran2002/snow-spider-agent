WITH days_per_station AS (
  SELECT `stn`, COUNT(DISTINCT PARSE_DATE('%Y-%m-%d', CONCAT(`year`, '-', `mo`, '-', `da`))) AS days_with_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE `temp` != 9999.9
  GROUP BY `stn`
),
stations_with_90_percent AS (
  SELECT COUNT(*) AS count_90_percent
  FROM days_per_station
  WHERE days_with_temp >= 329
),
total_stations AS (
  SELECT COUNT(DISTINCT `stn`) AS total_stations
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
)
SELECT
  ROUND((stations_with_90_percent.count_90_percent / total_stations.total_stations)*100, 4) AS Percentage_of_Stations
FROM stations_with_90_percent, total_stations;