-- Task: For each neighborhood in San Francisco, provide the neighborhood name along with the total number of bike share stations located there.
WITH station_neighborhoods AS (
   SELECT
       bs.station_id,
       bs.name AS station_name,
       nb.neighborhood
   FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` bs
   JOIN
       `bigquery-public-data.san_francisco_neighborhoods.boundaries` nb
   ON 
       ST_INTERSECTS(ST_GEOGPOINT(bs.lon, bs.lat), nb.neighborhood_geom)
)
SELECT
    neighborhood,
    COUNT(station_id) AS station_count
FROM
    station_neighborhoods
GROUP BY
    neighborhood