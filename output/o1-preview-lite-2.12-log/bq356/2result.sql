SELECT COUNT(*) AS number_of_stations
FROM (
  SELECT gsod.stn, gsod.wban, COUNT(*) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2019` AS gsod
  JOIN `bigquery-public-data.noaa_gsod.stations` AS stations
    ON gsod.stn = stations.usaf AND gsod.wban = stations.wban
  WHERE stations.begin <= '20000101'
    AND stations.end >= '20190630'
    AND gsod.temp != 9999.9
    AND gsod.max != 9999.9
    AND gsod.min != 9999.9
  GROUP BY gsod.stn, gsod.wban
  HAVING COUNT(*) >= 329
);