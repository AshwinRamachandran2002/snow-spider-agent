WITH bike_station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS total_bike_share_stations
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_CONTAINS(n.neighborhood_geom, s.station_geom)
  WHERE s.station_geom IS NOT NULL
  GROUP BY n.neighborhood
),
crime_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS total_crime_incidents
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
    ON ST_CONTAINS(
         n.neighborhood_geom,
         ST_GEOGPOINT(c.longitude, c.latitude)
       )
  WHERE c.longitude IS NOT NULL
    AND c.latitude  IS NOT NULL
  GROUP BY n.neighborhood
)
SELECT
  b.neighborhood,
  b.total_bike_share_stations,
  c.total_crime_incidents
FROM bike_station_counts AS b
JOIN crime_counts        AS c
  USING (neighborhood)
ORDER BY neighborhood;