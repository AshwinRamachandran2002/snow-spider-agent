WITH type_totals AS (      -- complaint types used in the analysis
  SELECT complaint_type,
         COUNT(*) AS total_reqs
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY complaint_type
  HAVING total_reqs > 3000
),

-- total 311 requests per day
daily_totals AS (
  SELECT DATE(created_date)        AS day,
         COUNT(*)                  AS tot_reqs
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day
),

-- daily requests per (eligible) complaint type
daily_by_type AS (
  SELECT DATE(created_date)        AS day,
         complaint_type,
         COUNT(*)                  AS type_reqs
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
    AND complaint_type IN (SELECT complaint_type FROM type_totals)
  GROUP BY day, complaint_type
),

-- daily mean wind‑speed (knots) at JFK airport – NOAA station 744860
wind AS (
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS day,
    CAST(wdsp AS FLOAT64)                                           AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'      -- 2011‑2020 tables
    AND stn = '744860'                           -- JFK
    AND CAST(wdsp AS FLOAT64) != 999.9           -- remove missing value code
),

-- join data sets and build daily proportions
joined AS (
  SELECT
    t.complaint_type,
    t.day,
    SAFE_DIVIDE(CAST(t.type_reqs AS FLOAT64),
                CAST(d.tot_reqs  AS FLOAT64))    AS prop_requests,
    w.wind_knots
  FROM daily_by_type t
  JOIN daily_totals d USING (day)
  JOIN wind         w USING (day)
),

-- correlation of each complaint type with wind speed
correlations AS (
  SELECT
    complaint_type,
    CORR(prop_requests, wind_knots) AS corr_coef
  FROM joined
  GROUP BY complaint_type
),

-- strongest positive and strongest negative correlations
extremes AS (
  (SELECT complaint_type,
          ROUND(corr_coef, 4) AS correlation
   FROM correlations
   ORDER BY corr_coef DESC
   LIMIT 1)
  UNION ALL
  (SELECT complaint_type,
          ROUND(corr_coef, 4) AS correlation
   FROM correlations
   ORDER BY corr_coef ASC
   LIMIT 1)
)

SELECT * 
FROM extremes;