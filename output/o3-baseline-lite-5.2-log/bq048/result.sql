WITH -- 1.  311 complaints (2011‑2020) aggregated by day
complaints_by_day AS (
  SELECT
    DATE(`created_date`)           AS day,
    `complaint_type`,
    COUNT(*)                       AS n_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(`created_date`) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day, complaint_type
),

-- total complaints per day
totals_per_day AS (
  SELECT
    day,
    SUM(n_complaints) AS total_complaints
  FROM complaints_by_day
  GROUP BY day
),

-- daily proportion of each complaint type
daily_proportions AS (
  SELECT
    c.day,
    c.complaint_type,
    c.n_complaints / t.total_complaints AS proportion
  FROM complaints_by_day c
  JOIN totals_per_day t USING (day)
),

-- keep only complaint types that appeared more than 3 000 times in the decade
eligible_types AS (
  SELECT
    complaint_type
  FROM complaints_by_day
  GROUP BY complaint_type
  HAVING SUM(n_complaints) > 3000
),

daily_props_filtered AS (
  SELECT
    d.*
  FROM daily_proportions d
  JOIN eligible_types e USING (complaint_type)
),

-- 2.  Daily mean wind speed at station 744860 (JFK) from GSOD tables 2011‑2020
jfk_wind AS (
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS day,
    CAST(wdsp AS FLOAT64)                                        AS wind
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                  -- JFK Airport
    AND wdsp IS NOT NULL
    AND wdsp != '999.9'                 -- 999.9 denotes missing
),

-- 3.  Correlation between daily proportion and wind speed for each complaint type
correlations AS (
  SELECT
    dp.complaint_type,
    CORR(dp.proportion, jw.wind) AS corr_coef
  FROM daily_props_filtered dp
  JOIN jfk_wind jw USING (day)
  GROUP BY complaint_type
),

-- 4.  Identify strongest positive and strongest negative correlations
ranked AS (
  SELECT
    complaint_type,
    ROUND(corr_coef, 4) AS correlation,
    RANK() OVER (ORDER BY corr_coef DESC) AS pos_rnk,
    RANK() OVER (ORDER BY corr_coef ASC)  AS neg_rnk
  FROM correlations
)

SELECT
  complaint_type,
  correlation
FROM ranked
WHERE pos_rnk = 1         -- strongest positive
   OR neg_rnk = 1         -- strongest negative
ORDER BY correlation DESC; -- positive first, then negative