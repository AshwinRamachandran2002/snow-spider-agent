WITH wind AS (
  -- Daily mean wind speed (knots) at JFK Airport (station 744860)
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                                           AS date,
    AVG(CAST(wdsp AS FLOAT64))                                                AS avg_wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')  -- 2011‑2020 tables
    AND stn = '744860'                                -- JFK Airport
    AND wdsp NOT IN ('999.9', '9999.9')               -- remove “missing” codes
  GROUP BY date
),
complaints_daily AS (
  -- Daily counts by complaint type
  SELECT
    DATE(created_date)            AS date,
    complaint_type,
    COUNT(*)                      AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY date, complaint_type
),
daily_totals AS (
  -- Total complaints per day
  SELECT
    date,
    SUM(cnt) AS total_cnt
  FROM complaints_daily
  GROUP BY date
),
complaints_prop AS (
  -- Daily proportion of each complaint type
  SELECT
    cd.date,
    cd.complaint_type,
    cd.cnt / dt.total_cnt AS proportion
  FROM complaints_daily cd
  JOIN daily_totals dt USING (date)
),
types_over_3k AS (
  -- Complaint types with more than 3 000 requests in the decade
  SELECT complaint_type
  FROM complaints_daily
  GROUP BY complaint_type
  HAVING SUM(cnt) > 3000
),
joined AS (
  -- Join proportions with wind data
  SELECT
    cp.complaint_type,
    cp.proportion,
    w.avg_wind_speed
  FROM complaints_prop cp
  JOIN types_over_3k  USING (complaint_type)
  JOIN wind           w USING (date)
),
corr_by_type AS (
  -- Pearson correlation for each complaint type
  SELECT
    complaint_type,
    CORR(proportion, avg_wind_speed) AS corr_coef
  FROM joined
  GROUP BY complaint_type
  HAVING corr_coef IS NOT NULL
),
ranked AS (
  -- Rank to find strongest positive and strongest negative correlations
  SELECT
    complaint_type,
    corr_coef,
    ROW_NUMBER() OVER (ORDER BY corr_coef DESC) AS pos_rank,
    ROW_NUMBER() OVER (ORDER BY corr_coef ASC)  AS neg_rank
  FROM corr_by_type
)
-- Final answer: strongest positive (pos_rank = 1) and strongest negative (neg_rank = 1)
SELECT
  complaint_type,
  ROUND(corr_coef, 4) AS correlation_coefficient
FROM ranked
WHERE pos_rank = 1 OR neg_rank = 1
ORDER BY correlation_coefficient DESC;