-- Daily (US – UK) temperature differences for October 2023
WITH valid_obs AS (
  SELECT
    -- build a real date from the string parts in GSOD
    PARSE_DATE('%Y-%m-%d', CONCAT(gsod.year, '-', gsod.mo, '-', gsod.da)) AS obs_date,
    st.country,
    gsod.max AS max_temp_station,
    gsod.min AS min_temp_station,
    gsod.temp AS avg_temp_station          -- “temp” is already the daily mean at the station
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS gsod
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS st
    ON  gsod.stn  = st.usaf
    AND gsod.wban = st.wban
  WHERE gsod.year = '2023'
    AND gsod.mo   = '10'                   -- October only
    AND st.country IN ('US','UK')          -- keep US and UK stations
    -- filter out records with the GSOD “missing” sentinels
    AND gsod.max  < 900
    AND gsod.min  < 900
    AND gsod.temp < 900
),
daily_country AS (                          -- aggregate once per country‑day
  SELECT
    obs_date,
    country,
    MAX(max_temp_station)        AS max_temp,   -- country‑wide daily maximum of station maxima
    MIN(min_temp_station)        AS min_temp,   -- country‑wide daily minimum of station minima
    AVG(avg_temp_station)        AS avg_temp    -- mean of station daily averages
  FROM valid_obs
  GROUP BY obs_date, country
)
SELECT
  obs_date                                           AS date,
  MAX(CASE WHEN country = 'US' THEN max_temp END)
    - MAX(CASE WHEN country = 'UK' THEN max_temp END)   AS diff_max_temp,
  MAX(CASE WHEN country = 'US' THEN min_temp END)
    - MAX(CASE WHEN country = 'UK' THEN min_temp END)   AS diff_min_temp,
  MAX(CASE WHEN country = 'US' THEN avg_temp END)
    - MAX(CASE WHEN country = 'UK' THEN avg_temp END)   AS diff_avg_temp
FROM daily_country
GROUP BY obs_date
HAVING COUNTIF(country = 'US') > 0   -- make sure both countries exist that day
   AND COUNTIF(country = 'UK') > 0
ORDER BY obs_date;