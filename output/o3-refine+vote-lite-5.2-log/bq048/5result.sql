WITH weather AS (
  -- daily mean wind speed at JFK (station 744860), 2011‑2020
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
    AVG(CAST(wdsp AS FLOAT64))                            AS wdsp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'            -- choose years
        AND stn = '744860'                                 -- JFK Airport
        AND wdsp IS NOT NULL
        AND wdsp != '999.9'                                -- discard missing
  GROUP BY date
),
daily_totals AS (
  -- total 311 requests per day
  SELECT
    DATE(created_date)           AS date,
    COUNT(*)                     AS total_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
        AND created_date <  '2021-01-01'
  GROUP BY date
),
daily_by_type AS (
  -- daily counts for every complaint type
  SELECT
    DATE(created_date)           AS date,
    complaint_type,
    COUNT(*)                     AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
        AND created_date <  '2021-01-01'
  GROUP BY date, complaint_type
),
big_types AS (
  -- complaint types with > 3 000 requests in the period
  SELECT complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2011-01-01'
        AND created_date <  '2021-01-01'
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),
base AS (
  -- build full date × complaint‑type grid, fill zeros, attach wind
  SELECT
    w.date,
    bt.complaint_type,
    COALESCE(dbt.type_cnt, 0) AS type_cnt,
    dt.total_cnt,
    w.wdsp
  FROM weather w
  JOIN daily_totals  dt ON dt.date = w.date               -- keep only dates with weather & 311 data
  CROSS JOIN big_types bt
  LEFT JOIN daily_by_type dbt
         ON dbt.date = w.date AND dbt.complaint_type = bt.complaint_type
),
corrs AS (
  -- Pearson correlation for every complaint type
  SELECT
    complaint_type,
    CORR(SAFE_DIVIDE(type_cnt, total_cnt), wdsp) AS r
  FROM base
  GROUP BY complaint_type
),
extremes AS (
  -- strongest positive and strongest negative
  SELECT complaint_type, r
  FROM (
        (SELECT * FROM corrs ORDER BY r DESC LIMIT 1)
        UNION ALL
        (SELECT * FROM corrs ORDER BY r ASC LIMIT 1)
       )
)
SELECT
  complaint_type,
  ROUND(r, 4) AS correlation
FROM extremes
ORDER BY correlation DESC;