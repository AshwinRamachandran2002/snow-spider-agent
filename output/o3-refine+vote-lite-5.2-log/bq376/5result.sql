WITH station_counts AS (
  SELECT
    nb.neighborhood,
    COUNT(*) AS bike_share_stations
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS nb
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS st
    ON st.station_geom IS NOT NULL
   AND ST_CONTAINS(nb.neighborhood_geom, st.station_geom)
  GROUP BY nb.neighborhood
),
incident_counts AS (
  SELECT
    nb.neighborhood,
    COUNT(*) AS crime_incidents
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS nb
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS inc
    ON inc.latitude IS NOT NULL
   AND inc.longitude IS NOT NULL
   AND ST_CONTAINS(
         nb.neighborhood_geom,
         ST_GEOGPOINT(inc.longitude, inc.latitude)
       )
  GROUP BY nb.neighborhood
)

SELECT
  sc.neighborhood,
  sc.bike_share_stations,
  ic.crime_incidents
FROM station_counts AS sc
JOIN incident_counts AS ic
  USING (neighborhood)
ORDER BY neighborhood;