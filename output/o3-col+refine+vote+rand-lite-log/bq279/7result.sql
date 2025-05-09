WITH yearly_counts AS (
  SELECT
    EXTRACT(YEAR FROM modified_date) AS year,
    COUNT(DISTINCT IF(LOWER(status) = 'active',  station_id, NULL)) AS active_station_count,
    COUNT(DISTINCT IF(LOWER(status) = 'closed', station_id, NULL)) AS closed_station_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM modified_date) IN (2013, 2014)
  GROUP BY year
)

SELECT
  y.year,
  COALESCE(c.active_station_count, 0) AS active_station_count,
  COALESCE(c.closed_station_count, 0) AS closed_station_count
FROM (SELECT 2013 AS year UNION ALL SELECT 2014) AS y
LEFT JOIN yearly_counts AS c
USING (year)
ORDER BY year;