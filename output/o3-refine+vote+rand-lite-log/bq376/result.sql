-- Neighborhoods that have both bikeshare stations and crime incidents,
-- together with the number of stations and incidents in each.
WITH station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_CONTAINS(n.neighborhood_geom, s.station_geom)
  GROUP BY n.neighborhood
),
crime_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS crime_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
    ON c.latitude IS NOT NULL
   AND c.longitude IS NOT NULL
   AND ST_CONTAINS(
         n.neighborhood_geom,
         ST_GEOGPOINT(c.longitude, c.latitude)
       )
  GROUP BY n.neighborhood
)
SELECT
  sc.neighborhood,
  sc.station_cnt  AS total_bikeshare_stations,
  cc.crime_cnt    AS total_crime_incidents
FROM station_counts AS sc
JOIN crime_counts  AS cc
  ON sc.neighborhood = cc.neighborhood
ORDER BY sc.neighborhood;