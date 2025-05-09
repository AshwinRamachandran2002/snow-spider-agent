-- Average temperature, wind speed, and precipitation for LaGuardia Airport (station 725030)
-- on June 12 for each year 2011‑2020
WITH daily AS (
  SELECT
    CAST(CONCAT('20', _TABLE_SUFFIX) AS INT64)            AS year,        -- 2011 … 2020
    temp                                                  AS temp_f,      -- daily mean °F
    CAST(wdsp AS FLOAT64)                                 AS wdsp_knots,  -- daily mean wind speed (knots)
    prcp                                                  AS prcp_in      -- daily precipitation (inches)
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20') -- 2011‑2020 tables
    AND stn = '725030'   -- LaGuardia Airport USAF ID
    AND mo  = '06'       -- June
    AND da  = '12'       -- 12th day
    AND temp < 9000      -- exclude missing sentinels
)
SELECT
  year,
  ROUND(AVG(temp_f), 2)                       AS avg_temperature_f,
  ROUND(AVG(CASE WHEN wdsp_knots < 900 THEN wdsp_knots END), 2) AS avg_wind_speed_knots,
  ROUND(AVG(CASE WHEN prcp_in   < 99.99 THEN prcp_in   END), 2) AS precipitation_inches
FROM daily
GROUP BY year
ORDER BY year;