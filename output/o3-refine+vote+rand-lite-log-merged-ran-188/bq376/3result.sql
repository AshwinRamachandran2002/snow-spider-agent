WITH station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON ST_CONTAINS(n.neighborhood_geom, s.station_geom)
  GROUP BY
    n.neighborhood
),
incident_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS incident_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
  ON i.longitude IS NOT NULL
     AND i.latitude  IS NOT NULL
     AND ST_CONTAINS(
           n.neighborhood_geom,
           ST_GEOGPOINT(i.longitude, i.latitude)
         )
  GROUP BY
    n.neighborhood
)
SELECT
  sc.neighborhood,
  sc.station_count,
  ic.incident_count
FROM station_counts  AS sc
JOIN incident_counts AS ic
USING (neighborhood)
ORDER BY
  neighborhood;