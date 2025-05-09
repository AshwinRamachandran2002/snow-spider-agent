WITH types_gt3000 AS (   -- complaint types with > 3000 requests during 2011‑2020
  SELECT complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),
-- daily mean wind speed (knots) at station 744860 ‑ JFK
wind AS (
  SELECT
    DATE(CAST(year AS INT64),CAST(mo AS INT64),CAST(da AS INT64)) AS dt,
    CAST(wdsp AS FLOAT64)                                   AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'     -- 2011‑2020
        AND stn = '744860'
        AND CAST(wdsp AS FLOAT64) < 999         -- filter missing (999.9)
),
-- total 311 requests per day
daily_totals AS (
  SELECT DATE(created_date) AS dt,
         COUNT(*)          AS total_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY dt
),
-- counts per type per day (only types of interest)
complaint_counts AS (
  SELECT DATE(created_date) AS dt,
         complaint_type,
         COUNT(*)           AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
        AND complaint_type IN (SELECT complaint_type FROM types_gt3000)
  GROUP BY dt, complaint_type
),
-- build daily proportions (0 when no requests of that type on the day)
daily_props AS (
  SELECT
    w.dt,
    t.complaint_type,
    IFNULL(c.type_cnt,0) / dt.total_cnt AS prop,   -- proportion of complaints
    w.wind_speed
  FROM wind w
  CROSS JOIN types_gt3000              AS t
  LEFT  JOIN complaint_counts  c ON c.dt = w.dt AND c.complaint_type = t.complaint_type
  JOIN  daily_totals          dt ON dt.dt = w.dt
),
-- Pearson correlations between proportion & wind speed for every type
corrs AS (
  SELECT
    complaint_type,
    CORR(prop, wind_speed) AS corr_value
  FROM daily_props
  GROUP BY complaint_type
)
-- pick strongest positive and strongest negative correlations
SELECT
  complaint_type,
  ROUND(corr_value,4) AS correlation_coefficient
FROM (
  SELECT
    corrs.*,
    ROW_NUMBER() OVER (ORDER BY corr_value DESC) AS pos_rank,
    ROW_NUMBER() OVER (ORDER BY corr_value ASC)  AS neg_rank
  FROM corrs
)
WHERE pos_rank = 1 OR neg_rank = 1
ORDER BY correlation_coefficient DESC;