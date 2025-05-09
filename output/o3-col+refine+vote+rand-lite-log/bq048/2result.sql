WITH daily_counts AS (          -- complaints per type per day
  SELECT
    DATE(created_date)        AS day,
    complaint_type,
    COUNT(*)                  AS type_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY day, complaint_type
),
daily_totals AS (              -- total complaints per day
  SELECT
    day,
    SUM(type_count) AS total_requests
  FROM daily_counts
  GROUP BY day
),
daily_props AS (               -- proportion of each type each day
  SELECT
    dc.day,
    dc.complaint_type,
    SAFE_DIVIDE(dc.type_count, dt.total_requests) AS prop
  FROM daily_counts dc
  JOIN daily_totals dt USING (day)
),
wind AS (                       -- daily mean wind speed (knots) at JFK station
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS day,
    CAST(wdsp AS FLOAT64)                                     AS wdsp_knots
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE stn = '744860'
    AND year BETWEEN '2011' AND '2020'
    AND SAFE_CAST(wdsp AS FLOAT64) IS NOT NULL
    AND SAFE_CAST(wdsp AS FLOAT64) < 500                     -- exclude sentinel 999.9
),
correlations AS (               -- Pearson r for each complaint type
  SELECT
    dp.complaint_type,
    CORR(dp.prop, w.wdsp_knots) AS corr
  FROM daily_props dp
  JOIN wind w USING (day)
  GROUP BY dp.complaint_type
),
type_totals AS (                -- grand totals per complaint type
  SELECT
    complaint_type,
    SUM(type_count) AS total_requests
  FROM daily_counts
  GROUP BY complaint_type
),
filtered AS (                   -- keep only frequent types (>3 000 requests)
  SELECT
    c.complaint_type,
    c.corr
  FROM correlations c
  JOIN type_totals t USING (complaint_type)
  WHERE t.total_requests > 3000
    AND c.corr IS NOT NULL
),
extremes AS (                   -- strongest positive & strongest negative
  SELECT *
  FROM (
    SELECT
      complaint_type,
      corr,
      ROW_NUMBER() OVER (ORDER BY corr DESC) AS pos_rank,
      ROW_NUMBER() OVER (ORDER BY corr ASC)  AS neg_rank
    FROM filtered
  )
  WHERE pos_rank = 1 OR neg_rank = 1
)
SELECT
  complaint_type,
  ROUND(corr, 4) AS correlation
FROM extremes
ORDER BY correlation DESC;