WITH target_years AS (
  SELECT 2013 AS yr UNION ALL
  SELECT 2014
),
station_counts AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`) AS yr,
    `status`,
    COUNT(DISTINCT `station_id`) AS cnt
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM `modified_date`) IN (2013, 2014)
  GROUP BY yr, `status`
)
SELECT
  t.yr AS year,
  COALESCE(SUM(CASE WHEN s.status = 'active' THEN s.cnt END), 0) AS active_station_count,
  COALESCE(SUM(CASE WHEN s.status = 'closed' THEN s.cnt END), 0) AS closed_station_count
FROM target_years t
LEFT JOIN station_counts s
ON t.yr = s.yr
GROUP BY t.yr
ORDER BY t.yr;