-- Neighborhoods that contain ≥ 1 bike-share station AND ≥ 1 crime incident,
-- plus the totals for each measure
WITH station_cte AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS station_cnt
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  JOIN
    `bigquery-public-data.san_francisco_neighborhoods.boundaries`          AS n
  ON
    ST_CONTAINS(n.neighborhood_geom, s.station_geom)            -- spatial join
  GROUP BY
    n.neighborhood
),
crime_cte AS (
  SELECT
    n.neighborhood,
    COUNT(*) AS crime_cnt
  FROM
    `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
  JOIN
    `bigquery-public-data.san_francisco_neighborhoods.boundaries`      AS n
  ON
    ST_CONTAINS(
      n.neighborhood_geom,
      ST_GEOGPOINT(i.longitude, i.latitude)                 -- incident point
    )
  WHERE
    i.latitude  IS NOT NULL
    AND i.longitude IS NOT NULL                             -- keep valid points
  GROUP BY
    n.neighborhood
)
SELECT
  s.neighborhood,
  s.station_cnt,
  c.crime_cnt
FROM
  station_cte AS s
JOIN
  crime_cte   AS c
USING (neighborhood)                                         -- only those with both
ORDER BY
  neighborhood;