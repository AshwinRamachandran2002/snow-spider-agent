WITH
-- total 311 complaints per day (all types)
daily_total AS (
  SELECT
    DATE(created_date) AS day,
    COUNT(*)           AS total_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
    AND created_date <  '2021-01-01'
    AND created_date IS NOT NULL
  GROUP BY day
),

-- daily counts for each complaint type
daily_type AS (
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*)           AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
    AND created_date <  '2021-01-01'
    AND created_date IS NOT NULL
  GROUP BY day, complaint_type
),

-- complaint types with > 3 000 requests during 2011‑2020
filter_types AS (
  SELECT complaint_type
  FROM daily_type
  GROUP BY complaint_type
  HAVING SUM(type_cnt) > 3000
),

-- daily proportion of each (filtered) complaint type
proportions AS (
  SELECT
    d.day,
    ft.complaint_type,
    IFNULL(dt.type_cnt, 0) / CAST(d.total_cnt AS FLOAT64) AS prop
  FROM daily_total d
  CROSS JOIN filter_types ft
  LEFT JOIN daily_type dt
         ON dt.day = d.day
        AND dt.complaint_type = ft.complaint_type
),

-- daily mean wind speed (knots) at JFK airport (station 744860)
wind AS (
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS day,
    CAST(wdsp AS FLOAT64)                                           AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                 -- JFK Airport
    AND CAST(wdsp AS FLOAT64) < 999.0  -- exclude missing data
),

-- Pearson correlation between daily proportion and wind speed
corrs AS (
  SELECT
    p.complaint_type,
    CORR(p.prop, w.wind_knots) AS correlation_coefficient
  FROM proportions p
  JOIN wind w USING (day)
  GROUP BY p.complaint_type
)

-- strongest positive and strongest negative correlation
SELECT
  complaint_type,
  ROUND(correlation_coefficient, 4) AS correlation_coefficient
FROM (
  (SELECT * FROM corrs ORDER BY correlation_coefficient DESC LIMIT 1)
  UNION ALL
  (SELECT * FROM corrs ORDER BY correlation_coefficient ASC LIMIT 1)
)
ORDER BY correlation_coefficient DESC;