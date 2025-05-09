SELECT COUNT(*) AS Number_of_Stations
FROM (
  SELECT gsod.stn, gsod.wban,
         COUNT(*) AS total_days,
         SUM(CASE WHEN gsod.temp IS NOT NULL AND gsod.temp != 9999.9 THEN 1 ELSE 0 END) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod2019` AS gsod
  JOIN `bigquery-public-data.noaa_gsod.stations` AS stations
    ON gsod.stn = stations.usaf AND gsod.wban = stations.wban
  WHERE
    stations.begin IS NOT NULL
    AND stations.end IS NOT NULL
    AND SAFE.PARSE_DATE('%Y%m%d', stations.begin) IS NOT NULL
    AND SAFE.PARSE_DATE('%Y%m%d', stations.end) IS NOT NULL
    AND SAFE.PARSE_DATE('%Y%m%d', stations.begin) <= DATE '2000-01-01'
    AND SAFE.PARSE_DATE('%Y%m%d', stations.end) >= DATE '2019-06-30'
  GROUP BY gsod.stn, gsod.wban
  HAVING
    total_days >= 1
    AND valid_temp_days / total_days >= 0.9
) AS qualified_stations;