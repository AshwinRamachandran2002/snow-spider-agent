WITH years AS (
  SELECT 2013 AS year UNION ALL
  SELECT 2014
),
station_status AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`) AS year,
    `station_id`,
    LOWER(`status`) AS status
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
)
SELECT
  y.year,
  COUNT(DISTINCT CASE WHEN s.status IN ('active','open') THEN s.station_id END) AS active_station_count,
  COUNT(DISTINCT CASE WHEN s.status = 'closed' THEN s.station_id END)  AS closed_station_count
FROM years y
LEFT JOIN station_status s
ON y.year = s.year
GROUP BY y.year
ORDER BY y.year;