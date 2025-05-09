SELECT
  DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date_ymd
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'
  AND mo  = '10'
  AND temp < 9000        -- exclude missing temperature flag 9999.9
ORDER BY temp DESC
LIMIT 3;