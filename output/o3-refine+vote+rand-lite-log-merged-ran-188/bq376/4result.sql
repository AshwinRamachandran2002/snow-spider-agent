WITH station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON ST_WITHIN(s.station_geom, n.neighborhood_geom)
  GROUP BY n.neighborhood
),
crime_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS crime_count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
  ON ST_WITHIN(ST_GEOGPOINT(c.longitude, c.latitude), n.neighborhood_geom)
  WHERE c.longitude IS NOT NULL
    AND c.latitude IS NOT NULL
    AND NOT IS_NAN(c.longitude)
    AND NOT IS_NAN(c.latitude)
  GROUP BY n.neighborhood
)
SELECT
  sc.neighborhood,
  sc.station_count,
  cc.crime_count
FROM station_counts AS sc
JOIN crime_counts  AS cc
ON sc.neighborhood = cc.neighborhood
ORDER BY sc.neighborhood;