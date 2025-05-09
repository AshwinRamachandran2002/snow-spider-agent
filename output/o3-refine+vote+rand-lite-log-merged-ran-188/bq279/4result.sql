WITH years AS (
  -- years we are interested in
  SELECT year
  FROM UNNEST([2013, 2014]) AS year
),
station_status AS (
  -- keep only rows from the two years in question
  SELECT
    EXTRACT(YEAR FROM modified_date) AS year,
    station_id,
    LOWER(status) AS status
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM modified_date) IN (2013, 2014)
)
SELECT
  y.year,
  COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.station_id END) AS active_station_count,
  COUNT(DISTINCT CASE WHEN s.status = 'closed' THEN s.station_id END) AS closed_station_count
FROM years AS y
LEFT JOIN station_status AS s
  ON y.year = s.year
GROUP BY y.year
ORDER BY y.year;