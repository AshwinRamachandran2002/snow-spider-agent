-- Neighborhoods that contain BOTH at least one bike-share station and one crime incident,
-- together with total counts of stations and incidents
WITH station_counts AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS station_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_CONTAINS(b.neighborhood_geom, s.station_geom)
  GROUP BY b.neighborhood
),
incident_counts AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS incident_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(i.longitude, i.latitude))
  WHERE i.longitude IS NOT NULL
    AND i.latitude  IS NOT NULL
  GROUP BY b.neighborhood
)

SELECT
  sc.neighborhood,
  sc.station_count,
  ic.incident_count
FROM station_counts AS sc
JOIN incident_counts AS ic
USING (neighborhood)         -- keeps only neighborhoods present in BOTH tables
ORDER BY sc.neighborhood;