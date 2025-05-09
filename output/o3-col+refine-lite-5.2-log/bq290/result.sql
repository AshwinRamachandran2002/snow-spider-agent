-- Daily temperature differences between U.S. and U.K. stations – October 2023
WITH us_daily AS (
  SELECT
    DATE(CAST(`year` AS INT64),
         CAST(`mo`   AS INT64),
         CAST(`da`   AS INT64))           AS day,
    MAX(`max`)                           AS max_us,
    MIN(`min`)                           AS min_us,
    AVG(`temp`)                          AS avg_us
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.`stn`  = s.`usaf`
   AND g.`wban` = s.`wban`
  WHERE s.`country` = 'US'          -- U.S. stations only
    AND g.`year`   = '2023'
    AND g.`mo`     = '10'           -- October
    -- discard missing / placeholder values
    AND g.`temp` < 9999
    AND g.`max`  < 9999
    AND g.`min`  < 9999
  GROUP BY day
),
uk_daily AS (
  SELECT
    DATE(CAST(`year` AS INT64),
         CAST(`mo`   AS INT64),
         CAST(`da`   AS INT64))           AS day,
    MAX(`max`)                           AS max_uk,
    MIN(`min`)                           AS min_uk,
    AVG(`temp`)                          AS avg_uk
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.`stn`  = s.`usaf`
   AND g.`wban` = s.`wban`
  WHERE s.`country` IN ('UK','GB')  -- United Kingdom stations
    AND g.`year`   = '2023'
    AND g.`mo`     = '10'           -- October
    AND g.`temp` < 9999
    AND g.`max`  < 9999
    AND g.`min`  < 9999
  GROUP BY day
)

SELECT
  us.day                                            AS date,
  us.max_us - uk.max_uk                             AS diff_max_temp,
  us.min_us - uk.min_uk                             AS diff_min_temp,
  us.avg_us - uk.avg_uk                             AS diff_avg_temp
FROM us_daily AS us
JOIN uk_daily AS uk
  USING (day)
ORDER BY date;