SELECT
  gsod.da AS day,
  AVG(CASE WHEN stations.country = 'US' THEN gsod.temp ELSE NULL END) AS avg_temp_US,
  AVG(CASE WHEN stations.country = 'GB' THEN gsod.temp ELSE NULL END) AS avg_temp_UK,
  MAX(CASE WHEN stations.country = 'US' THEN gsod.max ELSE NULL END) AS max_temp_US,
  MAX(CASE WHEN stations.country = 'GB' THEN gsod.max ELSE NULL END) AS max_temp_UK,
  MIN(CASE WHEN stations.country = 'US' THEN gsod.min ELSE NULL END) AS min_temp_US,
  MIN(CASE WHEN stations.country = 'GB' THEN gsod.min ELSE NULL END) AS min_temp_UK,
  AVG(CASE WHEN stations.country = 'US' THEN gsod.temp ELSE NULL END) -
  AVG(CASE WHEN stations.country = 'GB' THEN gsod.temp ELSE NULL END) AS avg_temp_difference,
  MAX(CASE WHEN stations.country = 'US' THEN gsod.max ELSE NULL END) -
  MAX(CASE WHEN stations.country = 'GB' THEN gsod.max ELSE NULL END) AS max_temp_difference,
  MIN(CASE WHEN stations.country = 'US' THEN gsod.min ELSE NULL END) -
  MIN(CASE WHEN stations.country = 'GB' THEN gsod.min ELSE NULL END) AS min_temp_difference
FROM `bigquery-public-data.noaa_gsod.gsod2023` AS gsod
JOIN `bigquery-public-data.noaa_gsod.stations` AS stations
  ON gsod.stn = stations.usaf AND gsod.wban = stations.wban
WHERE gsod.year = '2023' AND gsod.mo = '10'
  AND stations.country IN ('US', 'GB')
  AND gsod.temp != 9999.9 AND gsod.max != 9999.9 AND gsod.min != 9999.9
GROUP BY day
ORDER BY day;