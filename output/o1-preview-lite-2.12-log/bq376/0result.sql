WITH bike_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT s.station_id) AS Bike_Share_Stations_Count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_WITHIN(ST_GEOGPOINT(s.lon, s.lat), b.neighborhood_geom)
  GROUP BY b.neighborhood
),
crime_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT i.pdid) AS Crime_Incidents_Count
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
    ON ST_WITHIN(ST_GEOGPOINT(i.longitude, i.latitude), b.neighborhood_geom)
  GROUP BY b.neighborhood
)
SELECT
  bike_counts.Neighborhood_Name,
  bike_counts.Bike_Share_Stations_Count,
  crime_counts.Crime_Incidents_Count
FROM bike_counts
JOIN crime_counts
  ON bike_counts.Neighborhood_Name = crime_counts.Neighborhood_Name
ORDER BY Neighborhood_Name;