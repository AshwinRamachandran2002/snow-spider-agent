-- Top-5 highest daily-average wind–speed observations (2005-2015)
WITH daily_avg AS (
  SELECT
    DATE(year , month , day)               AS obs_date ,
    latitude ,
    longitude ,
    AVG(wind_speed)                        AS avg_daily_wind
  FROM `bigquery-public-data.noaa_icoads.icoads_core_*`
  WHERE
        REGEXP_CONTAINS(_TABLE_SUFFIX , r'^20\d{2}$')         -- keep yearly tables
    AND CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2005 AND 2015    -- 2005-2015 only
    AND wind_speed IS NOT NULL                                -- exclude missing
    AND NOT IS_NAN(wind_speed)
  GROUP BY obs_date , latitude , longitude
),
ranked AS (
  SELECT
    obs_date ,
    latitude ,
    longitude ,
    avg_daily_wind ,
    DENSE_RANK() OVER (ORDER BY avg_daily_wind DESC) AS rnk
  FROM daily_avg
)
SELECT
  obs_date ,
  latitude ,
  longitude ,
  avg_daily_wind
FROM ranked
WHERE rnk <= 5
ORDER BY avg_daily_wind DESC;