WITH station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON s.lat IS NOT NULL
       AND s.lon IS NOT NULL
       AND NOT (s.lat = 0 AND s.lon = 0)          -- filter out dummy coordinates
       AND ST_WITHIN(ST_GEOGPOINT(s.lon, s.lat), n.neighborhood_geom)
  GROUP BY n.neighborhood
),
incident_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS incident_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
    ON i.latitude IS NOT NULL
       AND i.longitude IS NOT NULL
       AND ST_WITHIN(ST_GEOGPOINT(i.longitude, i.latitude), n.neighborhood_geom)
  GROUP BY n.neighborhood
)

SELECT
  s.neighborhood,
  s.station_cnt,
  i.incident_cnt
FROM station_counts AS s
JOIN incident_counts AS i
USING (neighborhood)
ORDER BY neighborhood;