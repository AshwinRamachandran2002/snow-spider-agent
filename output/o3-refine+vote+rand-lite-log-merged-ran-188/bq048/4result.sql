WITH wind_raw AS (   -- JFK Airport = station 744860
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS day,
    SAFE_CAST(wdsp AS FLOAT64)                                   AS wdsp_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'      -- years 2011‑2020
    AND stn = '744860'                              -- JFK station
),
wind AS (
  SELECT day, AVG(wdsp_knots) AS wind_speed
  FROM wind_raw
  WHERE wdsp_knots IS NOT NULL AND wdsp_knots < 999      -- remove “missing” 999.9
  GROUP BY day
),

-- 311 complaints 2011‑2020
complaints AS (
  SELECT DATE(created_date) AS day, complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
    AND complaint_type IS NOT NULL
),

-- daily totals
daily_tot AS (
  SELECT day, COUNT(*) AS total_cnt
  FROM complaints
  GROUP BY day
),
daily_type AS (
  SELECT day, complaint_type, COUNT(*) AS type_cnt
  FROM complaints
  GROUP BY day, complaint_type
),

-- keep complaint types with > 3000 requests over the decade
type_totals AS (
  SELECT complaint_type, SUM(type_cnt) AS total_requests
  FROM daily_type
  GROUP BY complaint_type
  HAVING total_requests > 3000
),

-- daily proportions of those complaint types
daily_prop AS (
  SELECT
    dt.day,
    dt.complaint_type,
    dt.type_cnt / dtot.total_cnt AS prop
  FROM daily_type dt
  JOIN daily_tot  dtot ON dt.day = dtot.day
  JOIN type_totals tt ON dt.complaint_type = tt.complaint_type
),

-- correlation between proportion and wind speed
corrs AS (
  SELECT
    dp.complaint_type,
    CORR(dp.prop, w.wind_speed) AS corr_coeff
  FROM daily_prop dp
  JOIN wind w ON dp.day = w.day
  GROUP BY dp.complaint_type
),

-- pick strongest positive & negative
ranked AS (
  SELECT
    complaint_type,
    corr_coeff,
    ROW_NUMBER() OVER (ORDER BY corr_coeff DESC) AS pos_rank,
    ROW_NUMBER() OVER (ORDER BY corr_coeff ASC) AS neg_rank
  FROM corrs
)

SELECT
  complaint_type,
  ROUND(corr_coeff, 4) AS correlation
FROM ranked
WHERE pos_rank = 1 OR neg_rank = 1
ORDER BY correlation DESC;