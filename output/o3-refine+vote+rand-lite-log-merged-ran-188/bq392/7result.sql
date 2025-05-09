SELECT
  FORMAT_DATE('%Y-%m-%d',
              DATE(CAST(year AS INT64),
                   CAST(mo   AS INT64),
                   CAST(da   AS INT64))) AS date
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'        -- station number
  AND mo  = '10'            -- October
  AND temp < 9999.9         -- exclude missing temperature values
ORDER BY temp DESC, date
LIMIT 3;