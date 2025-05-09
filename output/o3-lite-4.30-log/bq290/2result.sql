WITH valid AS (
  SELECT
    g.date,
    CASE
      WHEN s.country IN ('UK','GB') THEN 'UK'   -- treat GB & UK as one group
      ELSE s.country
    END AS country,
    g.max  AS max_temp,
    g.min  AS min_temp,
    g.temp AS mean_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.date BETWEEN '2023-10-01' AND '2023-10-31'
    AND g.max  <> 9999.9
    AND g.min  <> 9999.9
    AND g.temp <> 9999.9
    AND s.country IN ('US','UK','GB')
),
daily_country_avg AS (
  SELECT
    date,
    country,
    AVG(max_temp)  AS avg_max,
    AVG(min_temp)  AS avg_min,
    AVG(mean_temp) AS avg_mean
  FROM valid
  GROUP BY date, country
),
pivoted AS (
  SELECT
    date,
    MAX(IF(country = 'US', avg_max, NULL)) AS us_max,
    MAX(IF(country = 'US', avg_min, NULL)) AS us_min,
    MAX(IF(country = 'US', avg_mean, NULL)) AS us_mean,
    MAX(IF(country = 'UK', avg_max, NULL)) AS uk_max,
    MAX(IF(country = 'UK', avg_min, NULL)) AS uk_min,
    MAX(IF(country = 'UK', avg_mean, NULL)) AS uk_mean
  FROM daily_country_avg
  GROUP BY date
)
SELECT
  date,
  ROUND(us_max  - uk_max , 4) AS max_temperature_diff,
  ROUND(us_min  - uk_min , 4) AS min_temperature_diff,
  ROUND(us_mean - uk_mean, 4) AS avg_temperature_diff
FROM pivoted
ORDER BY date;