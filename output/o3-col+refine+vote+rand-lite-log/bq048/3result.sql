/*  Complaint types ( >3 000 occurrences, 2011-2020 ) that have the strongest
    positive and negative Pearson correlation between their daily share of 311
    requests and the daily average wind speed (knots) measured at JFK airport
    (weather-station 744860).                                         */

WITH base_311 AS (
  SELECT
    DATE(created_date) AS day,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
),

hi_types AS (           -- complaint types with >3 000 requests
  SELECT complaint_type
  FROM base_311
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),

daily_type_cnt AS (     -- daily count for each high-volume type
  SELECT
    day,
    complaint_type,
    COUNT(*) AS n_type
  FROM base_311
  WHERE complaint_type IN (SELECT complaint_type FROM hi_types)
  GROUP BY day, complaint_type
),

daily_total AS (        -- daily total 311 requests (all types)
  SELECT
    day,
    COUNT(*) AS n_total
  FROM base_311
  GROUP BY day
),

daily_props AS (        -- daily proportion of each complaint type
  SELECT
    d.day,
    d.complaint_type,
    SAFE_DIVIDE(d.n_type, t.n_total) AS proportion
  FROM daily_type_cnt d
  JOIN daily_total t USING (day)
),

daily_wind AS (         -- daily mean wind speed (knots) at JFK, 2011-2020
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS day,
    CAST(wdsp AS FLOAT64)                AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE stn = '744860'
    AND CAST(wdsp AS FLOAT64) < 900                  -- exclude 999.9 “missing”
    AND CAST(year AS INT64) BETWEEN 2011 AND 2020
),

corrs AS (              -- Pearson correlation per complaint type
  SELECT
    p.complaint_type,
    CORR(p.proportion, w.wind_knots) AS r
  FROM daily_props p
  JOIN daily_wind w USING (day)
  GROUP BY p.complaint_type
),

extremes AS (           -- strongest positive and strongest negative
  (SELECT complaint_type,
          ROUND(r, 4) AS correlation
   FROM corrs
   ORDER BY r DESC
   LIMIT 1)
  UNION ALL
  (SELECT complaint_type,
          ROUND(r, 4) AS correlation
   FROM corrs
   ORDER BY r ASC
   LIMIT 1)
)

SELECT *
FROM extremes;