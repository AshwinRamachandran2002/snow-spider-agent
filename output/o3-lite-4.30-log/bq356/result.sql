SELECT
  COUNT(*) AS stations_meeting_criteria
FROM (
  SELECT
    g.stn,
    g.wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE s.begin <= '20000101'
    AND s.end   >= '20190630'
    AND g.temp <> 9999.9
    AND g.`max` <> 9999.9
    AND g.`min` <> 9999.9
  GROUP BY g.stn, g.wban
  HAVING valid_days_2019 >= 329   -- 90 % of 365
);