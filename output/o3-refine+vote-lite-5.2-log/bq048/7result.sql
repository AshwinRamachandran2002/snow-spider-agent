-- strongest positive and negative correlations between daily complaint share
-- and mean daily wind speed (JFK, station 744860) for 2011‑2020
WITH complaints_raw AS (
  SELECT
    DATE(created_date)                              AS date,
    complaint_type,
    COUNT(*)                                         AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
    AND created_date <  '2021-01-01'
  GROUP BY date, complaint_type
),
daily_totals AS (
  SELECT
    date,
    SUM(cnt) AS total_cnt
  FROM complaints_raw
  GROUP BY date
),
daily_props AS (
  SELECT
    r.date,
    r.complaint_type,
    CAST(r.cnt AS FLOAT64) / total_cnt              AS prop
  FROM complaints_raw r
  JOIN daily_totals t USING (date)
),
complaint_totals AS (          -- filter to types with >3000 requests
  SELECT complaint_type, SUM(cnt) AS total_requests
  FROM complaints_raw
  GROUP BY complaint_type
  HAVING total_requests > 3000
),
wind_daily AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS date,
    CAST(wdsp AS FLOAT64)                                                      AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                        -- JFK Airport
    AND CAST(wdsp AS FLOAT64) < 999           -- exclude missing 999.9
),
corrs AS (
  SELECT
    dp.complaint_type,
    CORR(dp.prop, w.wind_knots) AS r
  FROM daily_props dp
  JOIN wind_daily w USING (date)
  JOIN complaint_totals ct ON dp.complaint_type = ct.complaint_type
  GROUP BY dp.complaint_type
),
ordered AS (
  SELECT complaint_type, r,
         ROW_NUMBER() OVER (ORDER BY r DESC) AS pos_rank,
         ROW_NUMBER() OVER (ORDER BY r ASC ) AS neg_rank
  FROM corrs
  WHERE r IS NOT NULL
)
SELECT complaint_type, ROUND(r,4) AS correlation
FROM ordered
WHERE pos_rank = 1                       -- strongest positive
   OR neg_rank = 1                       -- strongest negative
ORDER BY correlation DESC;               -- positive first, then negative