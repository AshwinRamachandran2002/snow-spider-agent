WITH daily_temps AS (
  SELECT
    FORMAT('%s-%02d-%02d', year, CAST(mo AS INT64), CAST(da AS INT64)) AS date_iso,
    AVG(temp) AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2009`
  WHERE stn = '723758'
    AND mo = '10'               -- October
    AND temp < 9999.9           -- exclude missing temperature values
  GROUP BY date_iso
)
SELECT date_iso
FROM daily_temps
ORDER BY avg_temp DESC, date_iso
LIMIT 3;