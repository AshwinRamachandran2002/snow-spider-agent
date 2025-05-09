WITH years AS (
  SELECT 2013 AS year UNION ALL SELECT 2014
),
station_year_status AS (
  SELECT
    EXTRACT(YEAR FROM `modified_date`) AS year,
    `station_id`,
    LOWER(`status`) AS status
  FROM
    `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE
    EXTRACT(YEAR FROM `modified_date`) IN (2013, 2014)
),
aggregated AS (
  SELECT
    year,
    COUNT(DISTINCT IF(status = 'active', station_id, NULL)) AS active_stations,
    COUNT(DISTINCT IF(status = 'closed', station_id, NULL)) AS closed_stations
  FROM
    station_year_status
  GROUP BY
    year
)
SELECT
  y.year,
  COALESCE(a.active_stations, 0) AS active_stations,
  COALESCE(a.closed_stations, 0) AS closed_stations
FROM
  years AS y
LEFT JOIN
  aggregated AS a
USING (year)
ORDER BY
  year;