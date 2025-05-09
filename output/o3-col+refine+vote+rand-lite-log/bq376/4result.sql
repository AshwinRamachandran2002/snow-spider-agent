-- Neighborhoods that have (1) at least one bike-share station and 
-- (2) at least one crime incident, with totals for each

WITH bike_stations_by_neighborhood AS (
  SELECT
    nb.neighborhood,
    COUNT(DISTINCT si.station_id) AS bike_station_cnt
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries`           AS nb
    ON ST_WITHIN(ST_GEOGPOINT(si.lon , si.lat), nb.neighborhood_geom)
  GROUP BY nb.neighborhood
),
crime_incidents_by_neighborhood AS (
  SELECT
    nb.neighborhood,
    COUNT(DISTINCT inc.unique_key) AS crime_incident_cnt
  FROM `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS inc
  JOIN `bigquery-public-data.san_francisco_neighborhoods.boundaries`      AS nb
    ON ST_WITHIN(ST_GEOGPOINT(inc.longitude , inc.latitude), nb.neighborhood_geom)
  GROUP BY nb.neighborhood
)

SELECT
  bs.neighborhood,
  bs.bike_station_cnt,
  ci.crime_incident_cnt
FROM bike_stations_by_neighborhood   AS bs
JOIN crime_incidents_by_neighborhood AS ci
USING (neighborhood)
ORDER BY ci.crime_incident_cnt DESC;