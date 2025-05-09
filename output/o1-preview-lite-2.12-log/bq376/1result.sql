WITH bs_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT bs.station_id) AS Bike_Share_Stations_Count
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS bs
  ON
    ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(bs.lon, bs.lat))
  WHERE
    bs.lat IS NOT NULL AND bs.lon IS NOT NULL
  GROUP BY
    b.neighborhood
),
ci_counts AS (
  SELECT
    b.neighborhood AS Neighborhood_Name,
    COUNT(DISTINCT ci.unique_key) AS Crime_Incidents_Count
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS ci
  ON
    ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(ci.longitude, ci.latitude))
  WHERE
    ci.latitude IS NOT NULL AND ci.longitude IS NOT NULL
  GROUP BY
    b.neighborhood
)
SELECT
  bs_counts.Neighborhood_Name,
  bs_counts.Bike_Share_Stations_Count,
  ci_counts.Crime_Incidents_Count
FROM
  bs_counts
JOIN
  ci_counts
ON
  bs_counts.Neighborhood_Name = ci_counts.Neighborhood_Name
ORDER BY
  bs_counts.Neighborhood_Name;