SELECT
  n.neighborhood AS Neighborhood,
  (
    SELECT
      COUNT(DISTINCT bsi.station_id)
    FROM
      `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS bsi
    WHERE
      ST_Contains(n.neighborhood_geom, bsi.station_geom)
  ) AS Number_of_Bike_Share_Stations,
  (
    SELECT
      COUNT(si.unique_key)
    FROM
      `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS si
    WHERE
      si.longitude IS NOT NULL AND si.latitude IS NOT NULL
      AND
      ST_Contains(n.neighborhood_geom, ST_GEOGPOINT(si.longitude, si.latitude))
  ) AS Total_Number_of_Crime_Incidents
FROM
  `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS n
ORDER BY
  n.neighborhood;