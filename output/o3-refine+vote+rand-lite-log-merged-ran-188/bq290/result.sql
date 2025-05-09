/*  Daily October-2023 temperature differences (US – UK)  */
WITH daily AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(g.year , LPAD(g.mo,2,'0'), LPAD(g.da,2,'0'))) AS day,
    s.country,
    MAX(g.max)            AS d_max,   -- daily station maximum
    MIN(g.min)            AS d_min,   -- daily station minimum
    AVG(g.temp)           AS d_avg    -- daily station mean
  FROM  `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN  `bigquery-public-data.noaa_gsod.stations`  AS s
        ON g.stn  = s.usaf
       AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                 -- October 2023 only
    AND s.country IN ('US','UK')      
    -- discard records with the 9999.9 missing-value flag
    AND g.temp < 9000
    AND g.max  < 9000
    AND g.min  < 9000
  GROUP BY day , s.country
),
pivot AS (                      -- place the two countries on the same row
  SELECT
    day,
    MAX(IF(country='US', d_max, NULL)) AS us_max,
    MAX(IF(country='UK', d_max, NULL)) AS uk_max,
    MAX(IF(country='US', d_min, NULL)) AS us_min,
    MAX(IF(country='UK', d_min, NULL)) AS uk_min,
    MAX(IF(country='US', d_avg, NULL)) AS us_avg,
    MAX(IF(country='UK', d_avg, NULL)) AS uk_avg
  FROM  daily
  GROUP BY day
)
SELECT
  day                                           AS date,
  us_max - uk_max                               AS diff_max_temperature,
  us_min - uk_min                               AS diff_min_temperature,
  us_avg - uk_avg                               AS diff_avg_temperature
FROM   pivot
ORDER  BY date;