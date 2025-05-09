WITH station_counts AS (
  -- 1. Count bike‑share stations inside each neighborhood polygon
  SELECT
    b.neighborhood,
    COUNT(*) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
  ON  ST_CONTAINS(b.neighborhood_geom, s.station_geom)
  GROUP BY b.neighborhood
),
crime_counts AS (
  -- 2. Count crime incidents whose point falls inside the same polygons
  SELECT
    b.neighborhood,
    COUNT(*) AS crime_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
  ON  ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(c.longitude, c.latitude))
  WHERE c.longitude IS NOT NULL
    AND c.latitude  IS NOT NULL
  GROUP BY b.neighborhood
)
-- 3. Keep only neighborhoods that have both ≥1 bike station AND ≥1 crime
SELECT
  s.neighborhood,
  s.station_cnt  AS total_bike_share_stations,
  c.crime_cnt    AS total_crime_incidents
FROM station_counts AS s
JOIN crime_counts  AS c
USING (neighborhood)
ORDER BY s.neighborhood;