WITH bike_stations_per_neighborhood AS (
  SELECT
    n.neighborhood AS neighborhood,
    COUNT(bs.station_id) AS Number_of_Bike_Share_Stations
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  LEFT JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS bs
  ON
    ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(bs.lon, bs.lat))
  GROUP BY
    n.neighborhood
),

crime_incidents_per_neighborhood AS (
  SELECT
    n.neighborhood AS neighborhood,
    COUNT(ci.unique_key) AS Total_Number_of_Crime_Incidents
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
  LEFT JOIN
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS ci
  ON
    ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(ci.longitude, ci.latitude))
    AND ci.longitude BETWEEN -123 AND -122 AND ci.latitude BETWEEN 37 AND 38
  GROUP BY
    n.neighborhood
)

SELECT
  n.neighborhood,
  COALESCE(b.Number_of_Bike_Share_Stations, 0) AS Number_of_Bike_Share_Stations,
  COALESCE(c.Total_Number_of_Crime_Incidents, 0) AS Total_Number_of_Crime_Incidents
FROM
  `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
LEFT JOIN bike_stations_per_neighborhood AS b ON n.neighborhood = b.neighborhood
LEFT JOIN crime_incidents_per_neighborhood AS c ON n.neighborhood = c.neighborhood
ORDER BY n.neighborhood