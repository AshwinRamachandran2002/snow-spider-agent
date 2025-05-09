SELECT
  FORMAT_DATE('%Y-%m-%d',
              PARSE_DATE('%Y-%m-%d', CONCAT(year, '-', mo, '-', da))) AS date
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'
  AND mo = '10'
  AND temp < 9999      -- exclude missing temperature values
ORDER BY temp DESC, date
LIMIT 3;