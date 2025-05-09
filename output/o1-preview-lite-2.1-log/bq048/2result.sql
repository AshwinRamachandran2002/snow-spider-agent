WITH complaints AS (
  SELECT
    DATE(created_date) AS date,
    complaint_type,
    COUNT(*) AS num_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE
    latitude BETWEEN 40.60 AND 40.68
    AND longitude BETWEEN -73.82 AND -73.76
    AND EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY
    date, complaint_type
),
complaint_totals AS (
  SELECT
    complaint_type,
    SUM(num_complaints) AS total_complaints
  FROM
    complaints
  GROUP BY
    complaint_type
  HAVING
    total_complaints > 3000
),
filtered_complaints AS (
  SELECT
    c.date,
    c.complaint_type,
    c.num_complaints
  FROM
    complaints c
  JOIN
    complaint_totals ct
  ON
    c.complaint_type = ct.complaint_type
),
wind_data AS (
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo, 2, '0'), '-', LPAD(da, 2, '0'))) AS date,
    CAST(wdsp AS FLOAT64) AS windspeed_knots
  FROM
    `bigquery-public-data.noaa_gsod.gsod*`
  WHERE
    _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'
    AND wban = '94789'
    AND wdsp != '999.9'
    AND wdsp IS NOT NULL
),
correlations AS (
  SELECT
    fc.complaint_type,
    ROUND(CORR(fc.num_complaints, wd.windspeed_knots), 4) AS correlation
  FROM
    filtered_complaints fc
  JOIN
    wind_data wd
  ON
    fc.date = wd.date
  GROUP BY
    fc.complaint_type
)
SELECT
  complaint_type,
  correlation
FROM
  correlations
WHERE
  correlation = (SELECT MAX(correlation) FROM correlations)
  OR correlation = (SELECT MIN(correlation) FROM correlations)
ORDER BY
  correlation DESC;