WITH station_counts AS (
  -- count bike-share stations inside each neighborhood
  SELECT
    b.neighborhood,
    COUNT(si.station_id) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(si.lon, si.lat))
  GROUP BY b.neighborhood
),
incident_counts AS (
  -- count police incidents inside each neighborhood
  SELECT
    b.neighborhood,
    COUNT(ci.unique_key) AS incident_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS ci
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(ci.longitude, ci.latitude))
  GROUP BY b.neighborhood
)
-- return neighborhoods that have at least one station AND at least one incident
SELECT
  s.neighborhood           AS neighborhood_name,
  s.station_cnt            AS total_bike_share_stations,
  i.incident_cnt           AS total_crime_incidents
FROM station_counts AS s
JOIN incident_counts AS i
  ON s.neighborhood = i.neighborhood
ORDER BY neighborhood_name;