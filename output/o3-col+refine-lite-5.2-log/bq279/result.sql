WITH target_years AS (
  SELECT 2013 AS year UNION ALL
  SELECT 2014 AS year
),
station_counts AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`) AS year,
    COUNT(DISTINCT CASE WHEN LOWER(`status`) = 'active' THEN `station_id` END)  AS active_stations,
    COUNT(DISTINCT CASE WHEN LOWER(`status`) = 'closed' THEN `station_id` END) AS closed_stations
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM `modified_date`) IN (2013, 2014)   -- filter just the needed years
  GROUP BY year
)
SELECT
  y.year,
  COALESCE(sc.active_stations, 0) AS active_stations,
  COALESCE(sc.closed_stations, 0) AS closed_stations
FROM target_years AS y
LEFT JOIN station_counts AS sc USING (year)
ORDER BY y.year;