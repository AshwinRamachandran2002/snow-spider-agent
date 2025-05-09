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
    COUNT(DISTINCT s.station_id) AS station_count
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  JOIN
    neighborhoods AS n
  ON
    ST_WITHIN(s.station_geom, n.neighborhood_geom)
  GROUP BY
    n.neighborhood
),

-- crime incidents per neighborhood
incident_counts AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS incident_count
  FROM
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
  JOIN
    neighborhoods AS n
  ON
    ST_WITHIN(
      ST_GEOGPOINT(c.longitude, c.latitude),   -- create point for the incident
      n.neighborhood_geom
    )
  WHERE
    c.longitude IS NOT NULL
    AND c.latitude  IS NOT NULL
  GROUP BY
    n.neighborhood
)

-- neighborhoods that have both stations and incidents
SELECT
  sc.neighborhood,
  sc.station_count,
  ic.incident_count
FROM
  station_counts AS sc
JOIN
  incident_counts AS ic
USING (neighborhood)
ORDER BY
  sc.neighborhood;