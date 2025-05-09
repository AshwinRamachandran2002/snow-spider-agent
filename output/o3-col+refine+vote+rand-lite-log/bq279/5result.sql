-- Number of distinct ACTIVE and CLOSED bike-share stations for calendar-years 2013 and 2014
WITH station_counts AS (
  SELECT
    EXTRACT(YEAR FROM modified_date)      AS year,
    LOWER(status)                         AS station_status,
    COUNT(DISTINCT station_id)            AS distinct_station_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) IN ('active','closed')
  GROUP BY year, station_status
)

SELECT
  y.year,
  s.station_status,
  COALESCE(sc.distinct_station_count, 0)  AS distinct_station_count
FROM
  (SELECT year FROM UNNEST([2013, 2014]) AS year) AS y               -- target years
CROSS JOIN
  (SELECT station_status FROM UNNEST(['active','closed']) AS station_status) AS s  -- target statuses
LEFT JOIN station_counts sc
       ON sc.year = y.year
      AND sc.station_status = s.station_status
ORDER BY y.year, s.station_status;