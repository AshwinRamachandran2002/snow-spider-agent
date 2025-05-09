/* Complaint types (≥3 000 total requests, 2011‑2020) whose daily share of
   NYC 311 calls is most positively and most negatively correlated with
   daily mean wind speed at station 744860 (JFK Airport).               */
WITH
-- 1) Daily wind speed at JFK ------------------------------------------------
gsod AS (
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)) AS d,
         SAFE_CAST(wdsp AS FLOAT64)                         AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod2011`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2012`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2013`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2014`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2015`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2016`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2017`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2018`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
  UNION ALL
  SELECT PARSE_DATE('%Y-%m-%d', CONCAT(year,'-',mo,'-',da)), SAFE_CAST(wdsp AS FLOAT64)
  FROM `bigquery-public-data.noaa_gsod.gsod2020`
  WHERE stn = '744860' AND wdsp NOT IN ('999.9','9999.9')
),
-- 2) Total 311 requests per day --------------------------------------------
daily_tot AS (
  SELECT DATE(created_date) AS d,
         COUNT(*)           AS tot_reqs
  FROM   `bigquery-public-data.new_york.311_service_requests`
  WHERE  DATE(created_date) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP  BY d
),
-- 3) Daily count per complaint type ----------------------------------------
daily_type AS (
  SELECT DATE(created_date) AS d,
         complaint_type,
         COUNT(*)           AS n
  FROM   `bigquery-public-data.new_york.311_service_requests`
  WHERE  DATE(created_date) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP  BY d, complaint_type
),
-- 4) Daily proportion of each complaint type -------------------------------
props AS (
  SELECT dt.complaint_type,
         dt.d,
         dt.n,
         SAFE_DIVIDE(dt.n, t.tot_reqs) AS prop
  FROM   daily_type dt
  JOIN   daily_tot  t USING (d)
),
-- 5) Correlation between daily proportion and wind speed -------------------
corrs AS (
  SELECT p.complaint_type,
         CORR(p.prop, g.wind_knots) AS corr_coeff,
         SUM(p.n)                   AS total_reqs,
         COUNT(p.prop)              AS overlap_days
  FROM   props p
  JOIN   gsod  g USING (d)
  GROUP  BY p.complaint_type
  HAVING total_reqs  > 3000      -- complaint types with ≥3 000 requests
     AND overlap_days >= 30      -- at least 30 overlapping days
     AND corr_coeff IS NOT NULL
),
-- 6) Strongest positive and negative correlations --------------------------
pos AS (
  SELECT complaint_type,
         ROUND(corr_coeff, 4) AS correlation_coefficient
  FROM   corrs
  ORDER  BY corr_coeff DESC
  LIMIT  1
),
neg AS (
  SELECT complaint_type,
         ROUND(corr_coeff, 4) AS correlation_coefficient
  FROM   corrs
  ORDER  BY corr_coeff ASC
  LIMIT  1
)

-- 7) Final result -----------------------------------------------------------
SELECT complaint_type, correlation_coefficient FROM pos
UNION ALL
SELECT complaint_type, correlation_coefficient FROM neg;