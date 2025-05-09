--  Daily GSOD records already contain day‑averaged temperature (TEMP, °F),
--  wind speed (WDSP, kn) and total precipitation (PRCP, in).
--  This query pulls the 12 June row for LaGuardia airport (station 725030)
--  for each year 2011‑2020 and reports those values (ignoring GSOD “missing” codes).

WITH june12_lga AS (
  SELECT
    CAST(year AS INT64)            AS yr,
    -- replace GSOD “missing” codes with NULLs
    CASE WHEN temp  >= 9999 THEN NULL ELSE temp                       END AS temp_f,
    CASE WHEN SAFE_CAST(wdsp AS FLOAT64) >= 999
         THEN NULL ELSE SAFE_CAST(wdsp AS FLOAT64)                    END AS wind_kn,
    CASE WHEN prcp  >= 99.99 THEN NULL ELSE prcp                      END AS prcp_in
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE year BETWEEN '2011' AND '2020'      -- keep tables/rows for 2011‑2020
    AND stn  = '725030'                     -- LaGuardia (USAF 725030)
    AND mo   = '06'                         -- June
    AND da   = '12'                         -- 12‑June
)

SELECT
  yr                                          AS year,
  temp_f                                      AS avg_temperature_f,
  wind_kn                                     AS avg_wind_speed_knots,
  prcp_in                                     AS precipitation_inches
FROM june12_lga
ORDER BY year;