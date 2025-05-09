WITH station_counts AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS station_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
    ON ST_CONTAINS(b.neighborhood_geom, s.station_geom)
  GROUP BY b.neighborhood
),
crime_counts AS (
  SELECT
    b.neighborhood,
    COUNT(*) AS crime_cnt
  FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
  JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS c
    ON ST_CONTAINS(b.neighborhood_geom, ST_GEOGPOINT(c.longitude, c.latitude))
  WHERE c.longitude IS NOT NULL
    AND c.latitude  IS NOT NULL
  GROUP BY b.neighborhood
)
SELECT
  sc.neighborhood,
  sc.station_cnt AS total_bike_share_stations,
  cc.crime_cnt   AS total_crime_incidents
FROM station_counts AS sc
JOIN crime_counts  AS cc USING (neighborhood)
ORDER BY total_bike_share_stations DESC,
         total_crime_incidents   DESC;