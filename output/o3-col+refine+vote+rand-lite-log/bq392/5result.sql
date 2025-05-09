-- Top 3 hottest dates in October 2009 for station 723758
SELECT
  FORMAT('%s-%s-%s', year, LPAD(mo, 2, '0'), LPAD(da, 2, '0')) AS date
FROM (
  SELECT
    year,
    mo,
    da,
    AVG(temp) AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2009`
  WHERE stn = '723758'               -- station number
    AND mo = '10'                    -- October
    AND temp != 9999.9               -- exclude missing values
  GROUP BY year, mo, da
)
ORDER BY avg_temp DESC
LIMIT 3;