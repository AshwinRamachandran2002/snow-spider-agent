WITH neighborhoods AS (
  SELECT
    neighborhood,
    neighborhood_geom
  FROM
    `bigquery-public-data.san_francisco_neighborhoods.boundaries`
),
/* count bike‑share stations per neighborhood */
station_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS bike_station_count
  FROM
    neighborhoods AS n
  JOIN
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON
    ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(s.lon, s.lat))
  WHERE
    s.lat IS NOT NULL
    AND s.lon IS NOT NULL
  GROUP BY
    n.neighborhood
),
/* count crime incidents per neighborhood */
crime_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS crime_incident_count
  FROM
    neighborhoods AS n
  JOIN
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
  ON
    ST_CONTAINS(n.neighborhood_geom, ST_GEOGPOINT(c.longitude, c.latitude))
  WHERE
    c.latitude IS NOT NULL
    AND c.longitude IS NOT NULL
  GROUP BY
    n.neighborhood
)
/* keep only neighborhoods that have both a station and a crime */
SELECT
  sc.neighborhood,
  sc.bike_station_count,
  cc.crime_incident_count
FROM
  station_counts AS sc
JOIN
  crime_counts  AS cc
USING (neighborhood)
ORDER BY
  neighborhood;