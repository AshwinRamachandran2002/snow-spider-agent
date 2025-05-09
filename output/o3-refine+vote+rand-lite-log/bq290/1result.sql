-- Daily (US – UK) temperature differences for October 2023
WITH daily_country AS (
  SELECT
    -- build a DATE from the character year / month / day columns
    PARSE_DATE('%Y%m%d', CONCAT(gs.year, gs.mo, gs.da))        AS date,
    st.country                                                 AS country,
    -- highest reported daily maximum temperature (°F)
    MAX(CASE WHEN gs.max  < 9999 THEN gs.max  END)             AS max_temp,
    -- lowest reported daily minimum temperature (°F)
    MIN(CASE WHEN gs.min  < 9999 THEN gs.min  END)             AS min_temp,
    -- mean of station‑level average temperatures (°F)
    AVG(CASE WHEN gs.temp < 9999 THEN gs.temp END)             AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS gs
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS st
    ON gs.stn = st.usaf
   AND gs.wban = st.wban
  -- October 2023 only
  WHERE gs.mo = '10'
    AND st.country IN ('US','UK')            -- keep only USA and United Kingdom stations
  GROUP BY date, country
)

SELECT
  date,
  -- US – UK differences; NULL if either country missing that day
  MAX(IF(country = 'US', max_temp, NULL)) - MAX(IF(country = 'UK', max_temp, NULL)) AS diff_max_temperature,
  MAX(IF(country = 'US', min_temp, NULL)) - MAX(IF(country = 'UK', min_temp, NULL)) AS diff_min_temperature,
  MAX(IF(country = 'US', avg_temp, NULL)) - MAX(IF(country = 'UK', avg_temp, NULL)) AS diff_avg_temperature
FROM daily_country
GROUP BY date
ORDER BY date;