SELECT
  FORMAT('%04d-%02d-%02d',
         CAST(year AS INT64),
         CAST(mo   AS INT64),
         CAST(da   AS INT64)) AS hottest_date
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE stn = '723758'            -- Station number
  AND mo  = '10'                -- October
  AND temp < 9999.0             -- Exclude missing values
ORDER BY temp DESC              -- Highest mean temperatures first
LIMIT 3;                        -- Top 3 dates