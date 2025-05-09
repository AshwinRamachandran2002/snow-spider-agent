-- LaGuardia (USAF 725030) – daily values for 12-Jun, years 2011-2020
WITH daily AS (
  SELECT
    CAST(CONCAT('20', _TABLE_SUFFIX) AS INT64)          AS year,
    temp                                                AS temp_f,
    SAFE_CAST(NULLIF(wdsp, '999.9') AS FLOAT64)         AS wind_kt,
    NULLIF(prcp, 99.99)                                 AS prcp_in
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'             -- 2011-2020
    AND stn = '725030'                                  -- LaGuardia Airport
    AND mo  = '06'                                      -- June
    AND da  = '12'                                      -- 12th
)
SELECT
  year,
  ROUND(AVG(temp_f), 2)           AS avg_temp_f,
  ROUND(AVG(wind_kt), 2)          AS avg_wind_speed_kt,
  ROUND(AVG(prcp_in), 2)          AS prcp_in
FROM daily
GROUP BY year
ORDER BY year;