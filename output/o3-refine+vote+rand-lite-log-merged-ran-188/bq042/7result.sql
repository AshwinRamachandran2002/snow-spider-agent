-- Average daily temperature, wind speed, and precipitation for LaGuardia (USAF 725030)
-- on 12 June of each year 2011‑2020
WITH daily AS (
  SELECT
    2000 + CAST(_TABLE_SUFFIX AS INT64)          AS year,       -- 11 → 2011 … 20 → 2020
    temp                                         AS temp_f,
    SAFE_CAST(wdsp AS FLOAT64)                   AS wind_knots,
    prcp                                         AS prcp_in
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20') -- 2011‑2020
    AND stn = '725030'  -- LaGuardia Airport USAF identifier
    AND mo = '06'
    AND da = '12'
)
SELECT
  year,
  AVG(CASE WHEN temp_f   <  9999.9 THEN temp_f   END) AS avg_temp_fahrenheit,
  AVG(CASE WHEN wind_knots < 999.9  THEN wind_knots END) AS avg_wind_speed_knots,
  SUM(CASE WHEN prcp_in  <    99.99 THEN prcp_in  END) AS precipitation_inches
FROM daily
GROUP BY year
ORDER BY year;