WITH bike_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT bs.station_id) AS Bike_Share_Stations_Count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` bs
    ON ST_Contains(b.neighborhood_geom, bs.station_geom)
  GROUP BY b.neighborhood
),
crime_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT ci.unique_key) AS Crime_Incidents_Count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` ci
    ON ST_Contains(b.neighborhood_geom, ST_GeogPoint(ci.longitude, ci.latitude))
  WHERE ci.longitude IS NOT NULL AND ci.latitude IS NOT NULL
  GROUP BY b.neighborhood
)
SELECT
  bc.Neighborhood_Name,
  bc.Bike_Share_Stations_Count,
  cc.Crime_Incidents_Count
FROM bike_counts bc
JOIN crime_counts cc
  ON bc.Neighborhood_Name = cc.Neighborhood_Name
ORDER BY Neighborhood_Name;