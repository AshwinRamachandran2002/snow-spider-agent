WITH station_per_neighborhood AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
    ON s.station_geom IS NOT NULL
   AND ST_CONTAINS(b.neighborhood_geom, s.station_geom)
  GROUP BY b.neighborhood
),
crime_per_neighborhood AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS crime_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` i
    ON i.location IS NOT NULL
   AND ST_CONTAINS(b.neighborhood_geom, ST_GEOGFROMTEXT(i.location))
  GROUP BY b.neighborhood
)
SELECT
  s.neighborhood,
  s.station_cnt,
  c.crime_cnt
FROM station_per_neighborhood AS s
JOIN crime_per_neighborhood AS c USING (neighborhood)
ORDER BY s.neighborhood;