WITH base AS (          -- 1) join flights to airports & get lon/lat + English city names
  SELECT
    json_extract(dep.city,'$.en') AS dep_city ,
    json_extract(arr.city,'$.en') AS arr_city ,
    CAST(substr(dep.coordinates, 2,
         instr(dep.coordinates, ',') - 2) AS REAL) AS dep_lon ,
    CAST(substr(dep.coordinates,
         instr(dep.coordinates, ',') + 1,
         length(dep.coordinates) - instr(dep.coordinates, ',') - 1) AS REAL) AS dep_lat ,
    CAST(substr(arr.coordinates, 2,
         instr(arr.coordinates, ',') - 2) AS REAL) AS arr_lon ,
    CAST(substr(arr.coordinates,
         instr(arr.coordinates, ',') + 1,
         length(arr.coordinates) - instr(arr.coordinates, ',') - 1) AS REAL) AS arr_lat
  FROM flights        AS f
  JOIN airports_data  AS dep ON dep.airport_code = f.departure_airport
  JOIN airports_data  AS arr ON arr.airport_code = f.arrival_airport
),
flight_dist AS (        -- 2) great-circle distance per flight, build unordered key
  SELECT
    CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1 ,
    CASE WHEN dep_city > arr_city THEN dep_city ELSE arr_city END AS city2 ,
    6371.0 * acos(                 -- Earth radius * acos(…)
        cos(dep_lat * 0.0174532925199433) *
        cos(arr_lat * 0.0174532925199433) *
        cos((arr_lon - dep_lon) * 0.0174532925199433) +
        sin(dep_lat * 0.0174532925199433) *
        sin(arr_lat * 0.0174532925199433)
    ) AS distance_km
  FROM base
),
pair_avg AS (           -- 3) average distance for each unique unordered pair
  SELECT
    city1 ,
    city2 ,
    AVG(distance_km) AS avg_distance_km
  FROM flight_dist
  GROUP BY city1, city2
),
buckets AS (            -- 4) assign every pair to a distance range
  SELECT
    CASE
      WHEN avg_distance_km < 1000 THEN '0-999'
      WHEN avg_distance_km < 2000 THEN '1000-1999'
      WHEN avg_distance_km < 3000 THEN '2000-2999'
      WHEN avg_distance_km < 4000 THEN '3000-3999'
      WHEN avg_distance_km < 5000 THEN '4000-4999'
      WHEN avg_distance_km < 6000 THEN '5000-5999'
      ELSE '6000+'
    END AS distance_range
  FROM pair_avg
),
range_counts AS (       -- 5) how many pairs ended up in every range
  SELECT
    distance_range ,
    COUNT(*) AS pair_cnt
  FROM buckets
  GROUP BY distance_range
)
-- 6) the fewest number of unique city pairs among all ranges
SELECT MIN(pair_cnt) AS fewest_pairs
FROM   range_counts;