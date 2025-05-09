-- Average temperature (°F), wind speed (knots) and daily precipitation (inches)
-- for LaGuardia Airport (station USAF 725030) on 12 June in each year 2011‑2020
WITH daily AS (
  SELECT
    CAST(year AS INT64)                                 AS year,
    temp                                                AS temp_f,
    -- Convert wind‑speed text to FLOAT; set missing “999.9” to NULL
    NULLIF(CAST(wdsp AS FLOAT64), 999.9)                AS wind_knots,
    -- Convert precipitation; set missing “99.99” to NULL
    NULLIF(prcp, 99.99)                                 AS prcp_in
  FROM
    `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE
        _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')  -- 2011‑2020
    AND stn = '725030'      -- LaGuardia Airport USAF ID
    AND mo  = '06'          -- June
    AND da  = '12'          -- 12 June
)
SELECT
  year,
  AVG(temp_f)      AS avg_temp_f,
  AVG(wind_knots)  AS avg_wind_knots,
  AVG(prcp_in)     AS precipitation_in
FROM daily
GROUP BY year
ORDER BY year;