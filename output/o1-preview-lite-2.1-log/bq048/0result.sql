WITH complaint_counts AS (
  SELECT
    DATE(created_date) AS date,
    complaint_type,
    COUNT(*) AS daily_complaints
  FROM
    `bigquery-public-data.new_york.311_service_requests`
  WHERE
    EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-73.7781, 40.6413)  -- JFK Airport coordinates
    ) <= 5000  -- Within 5 km radius
  GROUP BY
    date,
    complaint_type
),
common_complaints AS (
  SELECT
    complaint_type
  FROM (
    SELECT
      complaint_type,
      SUM(daily_complaints) AS total_complaints
    FROM
      complaint_counts
    GROUP BY
      complaint_type
  )
  WHERE
    total_complaints > 3000
),
wind_data AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS date,
    AVG(CAST(NULLIF(wdsp, '999.9') AS FLOAT64)) AS wind_speed
  FROM
    `bigquery-public-data.noaa_gsod.gsod*`
  WHERE
    _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'    -- JFK Airport usaf code
    AND wban = '94789'    -- JFK Airport wban code
  GROUP BY
    date
),
complaint_correlations AS (
  SELECT
    cc.complaint_type,
    CORR(wd.wind_speed, cc.daily_complaints) AS correlation
  FROM
    complaint_counts AS cc
  JOIN
    common_complaints AS c ON cc.complaint_type = c.complaint_type
  JOIN
    wind_data AS wd ON cc.date = wd.date
  GROUP BY
    cc.complaint_type
),
ranked_correlations AS (
  SELECT
    complaint_type,
    ROUND(correlation, 4) AS correlation,
    ROW_NUMBER() OVER (ORDER BY correlation DESC) AS pos_rank,
    ROW_NUMBER() OVER (ORDER BY correlation ASC) AS neg_rank
  FROM
    complaint_correlations
)
SELECT
  complaint_type,
  correlation
FROM
  ranked_correlations
WHERE
  pos_rank = 1 OR neg_rank = 1
ORDER BY
  pos_rank;