SELECT COUNT(*) AS Number_of_Stations
FROM (
  SELECT stn, wban
  FROM (
    SELECT stn, wban, COUNT(*) AS num_valid_days,
           MAX(COUNT(*)) OVER () AS max_days
    FROM `bigquery-public-data.noaa_gsod.gsod2019`
    WHERE temp != 9999.9
    GROUP BY stn, wban
  )
  WHERE num_valid_days >= ROUND(0.9 * max_days, 4)
) AS temp_stations
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON temp_stations.stn = s.usaf AND temp_stations.wban = s.wban
WHERE PARSE_DATE('%Y%m%d', s.begin) <= DATE '2000-01-01'
  AND PARSE_DATE('%Y%m%d', s.end) >= DATE '2019-06-30';