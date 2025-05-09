SELECT
  s.neighborhood                           AS neighborhood,
  s.station_cnt                            AS total_bike_share_stations,
  i.crime_cnt                              AS total_crime_incidents
FROM
  ( SELECT
        b.neighborhood,
        COUNT(*) AS station_cnt
    FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS s
      ON ST_CONTAINS(b.neighborhood_geom , s.station_geom)
    GROUP BY b.neighborhood
  ) AS s
JOIN
  ( SELECT
        b.neighborhood,
        COUNT(*) AS crime_cnt
    FROM `bigquery-public-data.san_francisco_neighborhoods.boundaries` AS b
    JOIN `bigquery-public-data.san_francisco_sfpd_incidents.sfpd_incidents` AS i
      ON ST_CONTAINS(b.neighborhood_geom , ST_GEOGPOINT(i.longitude , i.latitude))
    WHERE i.latitude IS NOT NULL
      AND i.longitude IS NOT NULL
    GROUP BY b.neighborhood
  ) AS i
ON s.neighborhood = i.neighborhood
ORDER BY
  total_bike_share_stations DESC,
  total_crime_incidents     DESC;