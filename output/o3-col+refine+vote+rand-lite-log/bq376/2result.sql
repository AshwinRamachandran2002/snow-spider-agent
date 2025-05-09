-- Neighborhoods with at least one bike-share station AND at least one crime incident
WITH
-- 1. Count bike-share stations inside each neighborhood polygon
station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_WITHIN(ST_GEOGPOINT(s.lon, s.lat), n.neighborhood_geom)
  GROUP BY n.neighborhood
),

-- 2. Count crime incidents inside each neighborhood polygon
incident_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS incident_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
    ON i.latitude  IS NOT NULL
   AND i.longitude IS NOT NULL
   AND ST_WITHIN(ST_GEOGPOINT(i.longitude, i.latitude), n.neighborhood_geom)
  GROUP BY n.neighborhood
)

-- 3. Keep only neighborhoods appearing in both subqueries
SELECT
  s.neighborhood,
  s.station_count,
  i.incident_count
FROM station_counts AS s
JOIN incident_counts AS i
  USING (neighborhood)
ORDER BY neighborhood;