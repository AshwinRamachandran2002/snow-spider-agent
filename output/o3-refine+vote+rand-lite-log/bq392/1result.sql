SELECT
  CONCAT(year, '-', LPAD(mo, 2, '0'), '-', LPAD(da, 2, '0')) AS date
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'          -- station number
  AND mo  = '10'              -- October
  AND temp < 9999.9           -- exclude missing temperature values
ORDER BY temp DESC, date       -- highest average temperature first
LIMIT 3;