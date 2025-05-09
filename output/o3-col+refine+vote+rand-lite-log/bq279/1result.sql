-- Distinct ACTIVE and CLOSED bike-share stations for 2013 and 2014
WITH year_list AS (
  SELECT year FROM UNNEST([2013, 2014]) AS year
),
station_counts AS (
  SELECT
    EXTRACT(YEAR FROM modified_date) AS year,
    COUNT(DISTINCT IF(LOWER(status) = 'active', station_id, NULL)) AS active_cnt,
    COUNT(DISTINCT IF(LOWER(status) = 'closed', station_id, NULL)) AS closed_cnt
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE EXTRACT(YEAR FROM modified_date) IN (2013, 2014)
  GROUP BY year
)
SELECT
  y.year,
  COALESCE(s.active_cnt, 0) AS active_stations,
  COALESCE(s.closed_cnt, 0) AS closed_stations
FROM year_list y
LEFT JOIN station_counts s USING (year)
ORDER BY y.year;