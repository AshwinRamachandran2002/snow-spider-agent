SELECT
  FORMAT('%s-%s-%s',
         year,
         LPAD(mo, 2, '0'),
         LPAD(da, 2, '0')) AS date_yyyy_mm_dd
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'
  AND year = '2009'
  AND mo   = '10'
  AND temp < 9999.9          -- exclude missing values
ORDER BY temp DESC           -- highest mean temperatures first
LIMIT 3;