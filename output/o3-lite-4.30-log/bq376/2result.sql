WITH station_counts AS (
  SELECT
    b.neighborhood,
    COUNT(DISTINCT s.station_id) AS total_bike_share_stations
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries`          AS b
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(s.lon, s.lat))
  WHERE s.lat IS NOT NULL
    AND s.lon IS NOT NULL
  GROUP BY b.neighborhood
),
crime_counts AS (
  SELECT
    b.neighborhood,
    COUNT(DISTINCT i.unique_key) AS total_crime_incidents
  FROM `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries`       AS b
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(i.longitude, i.latitude))
  WHERE i.latitude IS NOT NULL
    AND i.longitude IS NOT NULL
  GROUP BY b.neighborhood
)
SELECT
  sc.neighborhood,
  sc.total_bike_share_stations,
  cc.total_crime_incidents
FROM station_counts AS sc
JOIN crime_counts  AS cc
USING (neighborhood)
ORDER BY
  cc.total_crime_incidents DESC,
  sc.neighborhood;