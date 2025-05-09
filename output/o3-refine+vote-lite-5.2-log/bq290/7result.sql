-- Daily (2023‑10‑01 … 2023‑10‑31) differences in U.S. – U.K. temperatures
WITH valid_temps AS (
  SELECT
    DATE(CAST(g.year AS INT64),
         CAST(g.mo   AS INT64),
         CAST(g.da   AS INT64))                         AS day,
    s.country                                           AS country,
    CAST(g.max  AS FLOAT64)                             AS max_t,
    CAST(g.min  AS FLOAT64)                             AS min_t,
    CAST(g.temp AS FLOAT64)                             AS avg_t
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                         -- October
    AND s.country IN ('US','UK')              -- keep only U.S. & U.K. stations
    -- remove rows with sentinel “missing” values
    AND g.max  <> 9999.9
    AND g.min  <> 9999.9
    AND g.temp <> 9999.9
),
country_day_avgs AS (
  SELECT
    day,
    country,
    AVG(max_t)  AS mean_max_t,
    AVG(min_t)  AS mean_min_t,
    AVG(avg_t)  AS mean_avg_t
  FROM valid_temps
  GROUP BY day, country
)

SELECT
  us.day                                                AS date,
  us.mean_max_t - uk.mean_max_t  AS diff_max_temperature,
  us.mean_min_t - uk.mean_min_t  AS diff_min_temperature,
  us.mean_avg_t - uk.mean_avg_t  AS diff_avg_temperature
FROM  country_day_avgs AS us
JOIN  country_day_avgs AS uk
  ON us.day = uk.day
WHERE us.country = 'US'
  AND uk.country = 'UK'
ORDER BY date;