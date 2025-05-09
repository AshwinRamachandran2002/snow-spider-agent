/*  Daily U.S.–minus–U.K. temperature differences for October-2023  */
WITH country_daily AS (
  SELECT
    DATE(CONCAT(g.year, '-', g.mo, '-', g.da))                    AS date,
    s.country                                                    AS country,
    MAX(g.max)                                                   AS max_temp,
    MIN(g.min)                                                   AS min_temp,
    AVG(g.temp)                                                  AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.mo = '10'                       -- October only
    AND s.country IN ('US','UK')          -- limit to the two countries
    -- discard placeholder / missing values
    AND g.temp < 9999
    AND g.max  < 9999
    AND g.min  < 9999
  GROUP BY date, country
),
pivot AS (
  SELECT
    date,
    MAX(IF(country = 'US', max_temp, NULL)) AS us_max,
    MAX(IF(country = 'UK', max_temp, NULL)) AS uk_max,
    MAX(IF(country = 'US', min_temp, NULL)) AS us_min,
    MAX(IF(country = 'UK', min_temp, NULL)) AS uk_min,
    MAX(IF(country = 'US', avg_temp, NULL)) AS us_avg,
    MAX(IF(country = 'UK', avg_temp, NULL)) AS uk_avg
  FROM country_daily
  GROUP BY date
)
SELECT
  date,
  us_max - uk_max  AS diff_max_temp,
  us_min - uk_min  AS diff_min_temp,
  us_avg - uk_avg  AS diff_avg_temp
FROM pivot
WHERE us_max IS NOT NULL               -- retain days present in both countries
  AND uk_max IS NOT NULL
ORDER BY date;