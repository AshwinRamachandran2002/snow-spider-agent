/*  strongest positive & negative correlations (Pearson) between daily
    average wind speed at JFK airport (station 744860 / WBAN 94789) and
    the daily proportion of each 311 complaint type (types with >3 000
    total requests, 2011-2020)                                            */

WITH daily_wind AS (           -- daily mean wind-speed (knots) at JFK
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0')))
        AS obs_date,
    SAFE_CAST(wdsp AS FLOAT64) AS mean_wind_kt
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')
    AND stn  = '744860'               -- USAF id  (JFK)
    AND wban = '94789'                -- WBAN id  (JFK)
    AND wdsp NOT IN ('999.9','999')   -- exclude “missing” codes
),
daily_311 AS (                 -- all 311 requests 2011-2020
  SELECT
    DATE(created_date) AS req_date,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
),
total_per_day AS (             -- total requests each day
  SELECT req_date, COUNT(*) AS tot_reqs
  FROM   daily_311
  GROUP  BY req_date
),
type_per_day AS (              -- requests per complaint type each day
  SELECT req_date, complaint_type, COUNT(*) AS type_reqs
  FROM   daily_311
  GROUP  BY req_date, complaint_type
),
popular_types AS (             -- complaint types with >3 000 requests
  SELECT complaint_type
  FROM   type_per_day
  GROUP  BY complaint_type
  HAVING SUM(type_reqs) > 3000
),
type_props AS (                -- daily proportion for each popular type
  SELECT
    t.req_date,
    t.complaint_type,
    SAFE_DIVIDE(t.type_reqs, d.tot_reqs) AS prop_reqs
  FROM   type_per_day   t
  JOIN   total_per_day  d USING (req_date)
  JOIN   popular_types  p USING (complaint_type)
),
aligned AS (                   -- align wind & proportions on same dates
  SELECT
    tp.complaint_type,
    tp.prop_reqs,
    dw.mean_wind_kt
  FROM   type_props tp
  JOIN   daily_wind dw
         ON dw.obs_date = tp.req_date
),
corrs AS (                     -- Pearson correlation per complaint type
  SELECT
    complaint_type,
    CORR(prop_reqs, mean_wind_kt) AS corr_coef
  FROM aligned
  GROUP BY complaint_type
),
ranked AS (                    -- identify strongest +ve and ‑ve
  SELECT
    complaint_type,
    corr_coef,
    ROW_NUMBER() OVER (ORDER BY corr_coef DESC) AS pos_rnk,
    ROW_NUMBER() OVER (ORDER BY corr_coef ASC)  AS neg_rnk
  FROM corrs
)
SELECT
  complaint_type,
  ROUND(corr_coef, 4) AS correlation_coefficient
FROM ranked
WHERE pos_rnk = 1 OR neg_rnk = 1
ORDER BY correlation_coefficient DESC;