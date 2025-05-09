WITH flight_data AS (
  SELECT 
    FL."flight_id",
    FL."departure_airport",
    FL."arrival_airport",
    GET(PARSE_JSON(DEP_AIR."city"), 'en')::STRING AS "departure_city",
    GET(PARSE_JSON(ARR_AIR."city"), 'en')::STRING AS "arrival_city",
    DEP_AIR."coordinates" AS "dep_coordinates",
    ARR_AIR."coordinates" AS "arr_coordinates"
  FROM AIRLINES.AIRLINES.FLIGHTS FL
  JOIN AIRLINES.AIRLINES.AIRPORTS_DATA DEP_AIR 
    ON FL."departure_airport" = DEP_AIR."airport_code"
  JOIN AIRLINES.AIRLINES.AIRPORTS_DATA ARR_AIR 
    ON FL."arrival_airport" = ARR_AIR."airport_code"
),
coordinate_pairs AS (
  SELECT
    LOWER(LEAST("departure_city", "arrival_city")) AS city1,
    LOWER(GREATEST("departure_city", "arrival_city")) AS city2,
    TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("dep_coordinates", '[()]', ''), ',', 1)) AS dep_lon,
    TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("dep_coordinates", '[()]', ''), ',', 2)) AS dep_lat,
    TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("arr_coordinates", '[()]', ''), ',', 1)) AS arr_lon,
    TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("arr_coordinates", '[()]', ''), ',', 2)) AS arr_lat
  FROM flight_data
  WHERE "departure_city" IS NOT NULL AND "arrival_city" IS NOT NULL
    AND "dep_coordinates" IS NOT NULL AND "arr_coordinates" IS NOT NULL
),
distance_calc AS (
  SELECT
    city1,
    city2,
    dep_lon,
    dep_lat,
    arr_lon,
    arr_lat,
    ST_DISTANCE(
      ST_MAKEPOINT(dep_lon, dep_lat),
      ST_MAKEPOINT(arr_lon, arr_lat)
    ) / 1000 AS distance_km  -- Convert meters to kilometers
  FROM coordinate_pairs
  WHERE dep_lon IS NOT NULL AND dep_lat IS NOT NULL AND arr_lon IS NOT NULL AND arr_lat IS NOT NULL
),
city_pair_distances AS (
  SELECT
    city1,
    city2,
    ROUND(AVG(distance_km), 4) AS avg_distance
  FROM distance_calc
  WHERE city1 != city2  -- Exclude same cities
  GROUP BY city1, city2
),
city_pair_ranges AS (
  SELECT
    city1,
    city2,
    avg_distance,
    CASE
      WHEN avg_distance < 1000 THEN '0-1000'
      WHEN avg_distance < 2000 THEN '1000-2000'
      WHEN avg_distance < 3000 THEN '2000-3000'
      WHEN avg_distance < 4000 THEN '3000-4000'
      WHEN avg_distance < 5000 THEN '4000-5000'
      WHEN avg_distance < 6000 THEN '5000-6000'
      ELSE '6000+'
    END AS distance_range
  FROM city_pair_distances
),
range_counts AS (
  SELECT
    distance_range,
    COUNT(*) AS num_pairs
  FROM city_pair_ranges
  GROUP BY distance_range
),
smallest_range AS (
  SELECT
    num_pairs
  FROM range_counts
  WHERE num_pairs = (SELECT MIN(num_pairs) FROM range_counts)
  LIMIT 1
)
SELECT num_pairs
FROM smallest_range;