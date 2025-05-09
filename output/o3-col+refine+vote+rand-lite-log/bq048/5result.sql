-- Complaint types (≥3 000 requests, 2011-2020) that show the strongest
-- positive and negative Pearson correlations between their daily
-- proportions and the daily mean wind-speed measured at JFK Airport
-- (station 744860).

WITH
-- 1️⃣  Daily mean wind-speed at JFK (2011-2020) ---------------------------
wind AS (
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS day,
    CAST(wdsp AS FLOAT64)                                    AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'         -- yearly tables
    AND stn  = '744860'                                 -- JFK Airport
    AND wdsp NOT IN ('999.9','9999.9')                  -- missing codes
),

-- 2️⃣  Daily totals of all 311 requests ----------------------------------
daily_tot AS (
  SELECT
    DATE(created_date)          AS day,
    COUNT(*)                    AS tot_all
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day
),

-- 3️⃣  Daily counts for each complaint type ------------------------------
daily_type AS (
  SELECT
    DATE(created_date)   AS day,
    complaint_type,
    COUNT(*)             AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY day, complaint_type
),

-- 4️⃣  Keep only complaint types with ≥3 000 total requests --------------
big_types AS (
  SELECT complaint_type
  FROM daily_type
  WHERE complaint_type IS NOT NULL
  GROUP BY complaint_type
  HAVING SUM(type_cnt) >= 3000
),

-- 5️⃣  Daily proportion of each big complaint type -----------------------
prop AS (
  SELECT
    w.day,
    bt.complaint_type,
    SAFE_DIVIDE(COALESCE(dt.type_cnt,0), dtot.tot_all) AS proportion,
    w.wind_speed
  FROM wind w
  CROSS JOIN big_types bt
  LEFT  JOIN daily_type dt
       ON dt.day = w.day
      AND dt.complaint_type = bt.complaint_type
  JOIN  daily_tot dtot
       ON dtot.day = w.day
),

-- 6️⃣  Pearson correlations ----------------------------------------------
corrs AS (
  SELECT
    complaint_type,
    CORR(proportion, wind_speed) AS r
  FROM prop
  GROUP BY complaint_type
  HAVING r IS NOT NULL
),

-- 7️⃣  Identify strongest positive & negative correlations ---------------
ranked AS (
  SELECT
    complaint_type,
    r,
    RANK() OVER (ORDER BY r DESC) AS pos_rank,
    RANK() OVER (ORDER BY r ASC ) AS neg_rank
  FROM corrs
)

-- ⏹️  Final answer --------------------------------------------------------
SELECT
  complaint_type,
  ROUND(r, 4) AS correlation
FROM ranked
WHERE pos_rank = 1 OR neg_rank = 1
ORDER BY correlation DESC;