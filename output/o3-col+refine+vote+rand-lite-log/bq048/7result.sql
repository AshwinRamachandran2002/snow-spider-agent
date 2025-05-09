-- Complaint types (≥3 000 requests, 2011-2020) with the strongest
-- positive and negative Pearson correlations between their daily
-- complaint-share and the daily-average wind speed at JFK Airport
WITH wind AS (                                       -- daily mean wind (knots)
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))          AS day,
    AVG(CAST(wdsp AS FLOAT64))               AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'        -- years of interest
    AND stn = '744860'                                 -- JFK Airport
    AND CAST(wdsp AS FLOAT64) < 900                    -- drop 999.9 sentinels
  GROUP BY day
),
complaints AS (                                       -- raw 311 rows
  SELECT
    DATE(created_date)        AS day,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
),
daily_totals AS (                                     -- total requests / day
  SELECT day, COUNT(*) AS total_daily
  FROM complaints
  GROUP BY day
),
daily_type AS (                                       -- per-type counts / day
  SELECT day, complaint_type, COUNT(*) AS type_daily
  FROM complaints
  GROUP BY day, complaint_type
),
type_totals AS (                                      -- overall totals / type
  SELECT complaint_type, SUM(type_daily) AS total_requests
  FROM daily_type
  GROUP BY complaint_type
),
daily_props AS (                                      -- daily proportion
  SELECT
    dt.day,
    dt.complaint_type,
    SAFE_DIVIDE(dt.type_daily, dtot.total_daily) AS prop
  FROM daily_type  dt
  JOIN daily_totals dtot USING (day)
),
corrs AS (                                            -- correlation per type
  SELECT
    dp.complaint_type,
    CORR(dp.prop , w.wind_knots) AS corr_coef
  FROM daily_props dp
  JOIN wind       w USING (day)
  GROUP BY dp.complaint_type
),
filtered AS (                                         -- keep ≥3 000 requests
  SELECT c.*
  FROM corrs           c
  JOIN type_totals tt USING (complaint_type)
  WHERE tt.total_requests > 3000
),
extremes AS (                                         -- strongest ± correlations
  (SELECT * FROM filtered ORDER BY corr_coef DESC LIMIT 1)
  UNION ALL
  (SELECT * FROM filtered ORDER BY corr_coef ASC LIMIT 1)
)
SELECT
  complaint_type,
  ROUND(corr_coef, 4) AS correlation
FROM extremes;