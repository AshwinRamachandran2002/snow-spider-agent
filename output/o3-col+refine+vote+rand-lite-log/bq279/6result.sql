-- Number of distinct bike-share stations by status for 2013 and 2014
WITH year_counts AS (
  SELECT
    EXTRACT(YEAR FROM modified_date) AS yr,
    status,
    COUNT(DISTINCT station_id) AS cnt
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE
    EXTRACT(YEAR FROM modified_date) IN (2013, 2014)
  GROUP BY
    yr,
    status
),
years AS (SELECT 2013 AS yr UNION ALL SELECT 2014),
statuses AS (SELECT 'active' AS status UNION ALL SELECT 'closed')
SELECT
  y.yr AS year,
  s.status,
  COALESCE(c.cnt, 0) AS distinct_station_cnt
FROM
  years AS y
CROSS JOIN
  statuses AS s
LEFT JOIN
  year_counts AS c
ON
  c.yr = y.yr
  AND c.status = s.status
ORDER BY
  year,
  status;