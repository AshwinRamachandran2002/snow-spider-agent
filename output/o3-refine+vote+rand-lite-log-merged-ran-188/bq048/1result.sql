/*  Complaint types (with >3,000 requests, 2011‑2020) showing the
    strongest positive and negative Pearson correlations between their
    daily complaint proportions and the daily mean wind speed measured
    at station 744860 (JFK Airport).                         */

WITH wind_raw AS (
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS day,
    CAST(wdsp AS FLOAT64)                           AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                    -- JFK Airport
    AND SAFE_CAST(wdsp AS FLOAT64) IS NOT NULL
    AND SAFE_CAST(wdsp AS FLOAT64) < 999.9           -- filter “missing”
),
daily_wind AS (
  SELECT
    day,
    AVG(wind_knots) AS wind_speed               -- one record per day
  FROM wind_raw
  GROUP BY day
),

-- 311 complaints aggregated by day and type
complaints AS (
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*)           AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day, complaint_type
),

-- total number of 311 complaints each day
daily_totals AS (
  SELECT
    day,
    SUM(cnt) AS total_cnt
  FROM complaints
  GROUP BY day
),

-- daily proportions for every complaint type
daily_props AS (
  SELECT
    c.day,
    c.complaint_type,
    c.cnt,
    c.cnt / t.total_cnt AS proportion
  FROM complaints c
  JOIN daily_totals t USING (day)
),

-- overall request totals per complaint type (to keep only those >3 000)
complaint_totals AS (
  SELECT
    complaint_type,
    SUM(cnt) AS total_reqs
  FROM complaints
  GROUP BY complaint_type
),

-- correlation between daily proportion and wind speed
corrs AS (
  SELECT
    dp.complaint_type,
    CORR(dp.proportion, dw.wind_speed) AS corr_coeff
  FROM daily_props dp
  JOIN daily_wind dw USING (day)
  JOIN complaint_totals ct USING (complaint_type)
  WHERE ct.total_reqs > 3000
  GROUP BY dp.complaint_type
),

-- rank to pick strongest positive and strongest negative
ranked AS (
  SELECT
    complaint_type,
    ROUND(corr_coeff, 4) AS correlation,
    RANK() OVER (ORDER BY corr_coeff DESC) AS pos_rank,
    RANK() OVER (ORDER BY corr_coeff ASC)  AS neg_rank
  FROM corrs
)

SELECT
  complaint_type,
  correlation
FROM ranked
WHERE pos_rank = 1
   OR neg_rank = 1
ORDER BY correlation DESC;