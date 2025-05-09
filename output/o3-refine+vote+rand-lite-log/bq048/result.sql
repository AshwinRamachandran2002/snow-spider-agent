-- strongest positive and negative correlations between daily complaint–type share
-- and mean wind speed at JFK airport (station 744860) during 2011‑2020
WITH wind AS (                      -- daily mean wind speed at JFK
  SELECT
    PARSE_DATE('%Y-%m-%d',
               CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS day,
    CAST(wdsp AS FLOAT64) AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'        -- 2011‑2020 tables
    AND stn = '744860'                             -- JFK Airport
    AND wdsp NOT IN ('999.9','9999.9')             -- remove missing values
),
complaints AS (                   -- daily counts per complaint type
  SELECT
    DATE(created_date)  AS day,
    complaint_type,
    COUNT(*)            AS n_requests
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day, complaint_type
),
daily_totals AS (                 -- total requests per day
  SELECT
    day,
    SUM(n_requests) AS total_requests
  FROM complaints
  GROUP BY day
),
ratios AS (                       -- daily proportion of each complaint type
  SELECT
    c.day,
    c.complaint_type,
    c.n_requests / t.total_requests AS share,
    w.wind_knots
  FROM complaints   c
  JOIN daily_totals t USING (day)
  JOIN wind         w USING (day)
),
large_types AS (                  -- complaint types with > 3000 requests over decade
  SELECT complaint_type
  FROM complaints
  GROUP BY complaint_type
  HAVING SUM(n_requests) > 3000
),
corrs AS (                        -- Pearson correlations
  SELECT
    complaint_type,
    CORR(share, wind_knots) AS r
  FROM ratios
  WHERE complaint_type IN (SELECT complaint_type FROM large_types)
  GROUP BY complaint_type
),
extremes AS (                     -- rows with max positive or max negative r
  SELECT *
  FROM corrs
  WHERE r = (SELECT MAX(r) FROM corrs)
     OR r = (SELECT MIN(r) FROM corrs)
)
SELECT
  complaint_type,
  ROUND(r, 4) AS correlation
FROM extremes;