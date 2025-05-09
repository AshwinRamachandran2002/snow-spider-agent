WITH station_counts AS (
  SELECT neighborhoods."neighborhood" AS neighborhood_name, COUNT(*) AS bike_share_station_count
  FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO" AS stations
  JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" AS neighborhoods
    ON ST_CONTAINS(
         ST_GEOGRAPHYFROMWKB(neighborhoods."neighborhood_geom"),
         ST_POINT(stations."lon", stations."lat")
       )
  GROUP BY neighborhoods."neighborhood"
),
incident_counts AS (
  SELECT neighborhoods."neighborhood" AS neighborhood_name, COUNT(*) AS crime_incident_count
  FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_SFPD_INCIDENTS"."SFPD_INCIDENTS" AS incidents
  JOIN "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_NEIGHBORHOODS"."BOUNDARIES" AS neighborhoods
    ON ST_CONTAINS(
         ST_GEOGRAPHYFROMWKB(neighborhoods."neighborhood_geom"),
         ST_POINT(incidents."longitude", incidents."latitude")
       )
  GROUP BY neighborhoods."neighborhood"
)
SELECT 
  station_counts.neighborhood_name, 
  station_counts.bike_share_station_count, 
  incident_counts.crime_incident_count
FROM station_counts
INNER JOIN incident_counts 
  ON station_counts.neighborhood_name = incident_counts.neighborhood_name;