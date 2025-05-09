WITH neighborhoods AS (
  SELECT
    neighborhood,
    neighborhood_geom
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries`
),
-- bike‑share stations per neighborhood
station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS bike_share_stations
  FROM
    neighborhoods AS n
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON
        s.lat IS NOT NULL
    AND s.lon IS NOT NULL
    AND ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(s.lon, s.lat))
  GROUP BY
    n.neighborhood
),
-- crime incidents per neighborhood
incident_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS crime_incidents
  FROM
    neighborhoods AS n
  JOIN
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
  ON
        i.location IS NOT NULL
    AND ST_CONTAINS(n.neighborhood_geom, ST_GEOGFROMTEXT(i.location))
  GROUP BY
    n.neighborhood
)
-- neighborhoods having both a station and at least one crime incident
SELECT
  s.neighborhood,
  s.bike_share_stations,
  i.crime_incidents
FROM
  station_counts AS s
JOIN
  incident_counts AS i
USING (neighborhood)
ORDER BY
  neighborhood;