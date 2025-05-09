WITH bike_neigh AS (
  SELECT
    nb.neighborhood,
    COUNT(DISTINCT bs.station_id) AS station_count
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS bs
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS nb
    ON ST_WITHIN(bs.station_geom, nb.neighborhood_geom)
  GROUP BY nb.neighborhood
),
crime_neigh AS (
  SELECT
    nb.neighborhood,
    COUNT(*) AS crime_count
  FROM `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS ci
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS nb
    ON ST_WITHIN(
         ST_GEOGPOINT(ci.longitude, ci.latitude),
         nb.neighborhood_geom
       )
  WHERE ci.longitude IS NOT NULL
    AND ci.latitude  IS NOT NULL
  GROUP BY nb.neighborhood
)
SELECT
  b.neighborhood,
  b.station_count,
  c.crime_count
FROM bike_neigh AS b
JOIN crime_neigh AS c
  ON b.neighborhood = c.neighborhood
ORDER BY b.neighborhood;