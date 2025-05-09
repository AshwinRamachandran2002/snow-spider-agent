WITH FlightDistances AS (
  SELECT
    LEAST(
      (PARSE_JSON(DEP."city"):"en")::STRING,
      (PARSE_JSON(ARR."city"):"en")::STRING
    ) AS "city1",
    GREATEST(
      (PARSE_JSON(DEP."city"):"en")::STRING,
      (PARSE_JSON(ARR."city"):"en")::STRING
    ) AS "city2",
    ST_POINT(
      CAST(TRIM(SPLIT(TRIM(DEP."coordinates", '()'), ',')[0]) AS FLOAT),
      CAST(TRIM(SPLIT(TRIM(DEP."coordinates", '()'), ',')[1]) AS FLOAT)
    ) AS "dep_point",
    ST_POINT(
      CAST(TRIM(SPLIT(TRIM(ARR."coordinates", '()'), ',')[0]) AS FLOAT),
      CAST(TRIM(SPLIT(TRIM(ARR."coordinates", '()'), ',')[1]) AS FLOAT)
    ) AS "arr_point"
  FROM AIRLINES.AIRLINES."FLIGHTS" F
  JOIN AIRLINES.AIRLINES."AIRPORTS_DATA" DEP
    ON F."departure_airport" = DEP."airport_code"
  JOIN AIRLINES.AIRLINES."AIRPORTS_DATA" ARR
    ON F."arrival_airport" = ARR."airport_code"
  WHERE DEP."coordinates" IS NOT NULL AND ARR."coordinates" IS NOT NULL
),
Distances AS (
  SELECT
    "city1",
    "city2",
    ROUND(ST_DISTANCE("dep_point", "arr_point") / 1000, 4) AS "distance_km"
  FROM FlightDistances
),
AverageDistances AS (
  SELECT
    "city1",
    "city2",
    ROUND(AVG("distance_km"), 4) AS "avg_distance_km"
  FROM Distances
  GROUP BY
    "city1",
    "city2"
),
DistanceRanges AS (
  SELECT
    "city1",
    "city2",
    "avg_distance_km",
    CASE
      WHEN "avg_distance_km" < 1000 THEN '0-999 km'
      WHEN "avg_distance_km" < 2000 THEN '1000-1999 km'
      WHEN "avg_distance_km" < 3000 THEN '2000-2999 km'
      WHEN "avg_distance_km" < 4000 THEN '3000-3999 km'
      WHEN "avg_distance_km" < 5000 THEN '4000-4999 km'
      WHEN "avg_distance_km" < 6000 THEN '5000-5999 km'
      ELSE '6000 km and above'
    END AS "distance_range"
  FROM AverageDistances
),
RangeCounts AS (
  SELECT
    "distance_range",
    COUNT(*) AS "num"
  FROM DistanceRanges
  GROUP BY "distance_range"
),
MinRange AS (
  SELECT
    MIN("num") AS "num"
  FROM RangeCounts
)
SELECT
  "num" AS "Number_of_Pairs_in_Smallest_Range"
FROM MinRange;