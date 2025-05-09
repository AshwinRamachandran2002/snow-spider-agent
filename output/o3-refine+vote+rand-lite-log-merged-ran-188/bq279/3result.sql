WITH years AS (
  SELECT 2013 AS year UNION ALL
  SELECT 2014
),
station_status AS (
  SELECT
    EXTRACT(YEAR FROM modified_date) AS year,
    station_id,
    LOWER(status) AS status
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM modified_date) BETWEEN 2013 AND 2014
),
counts AS (
  SELECT
    year,
    COUNT(DISTINCT CASE WHEN status = 'active' THEN station_id END)  AS active_station_count,
    COUNT(DISTINCT CASE WHEN status = 'closed' THEN station_id END) AS closed_station_count
  FROM station_status
  GROUP BY year
)
SELECT
  y.year,
  COALESCE(c.active_station_count, 0) AS active_station_count,
  COALESCE(c.closed_station_count, 0) AS closed_station_count
FROM years AS y
LEFT JOIN counts AS c
USING (year)
ORDER BY y.year;