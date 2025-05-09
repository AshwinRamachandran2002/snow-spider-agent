WITH coords AS (
  SELECT
      airport_code,
      /* longitude = text between "(" and "," */
      CAST(SUBSTR(coordinates, 2, INSTR(coordinates, ',')-2) AS REAL)           AS lon,
      /* latitude  = text between "," and ")" */
      CAST(SUBSTR(coordinates,
                  INSTR(coordinates, ',')+1,
                  LENGTH(coordinates) - INSTR(coordinates, ',') - 1) AS REAL)   AS lat,
      json_extract(city,'$.en')                                                 AS city_en
  FROM airports_data
),
legs AS (
  /* every scheduled flight leg with its great-circle distance */
  SELECT
      json_extract(a1.city,'$.en')                               AS city1,
      json_extract(a2.city,'$.en')                               AS city2,
      6371 * 2 * ASIN(
           SQRT(
               POWER(SIN(((c2.lat-c1.lat) * 0.01745329252)/2),2) +
               COS(c1.lat*0.01745329252) * COS(c2.lat*0.01745329252) *
               POWER(SIN(((c2.lon-c1.lon) * 0.01745329252)/2),2)
           )
      )                                                          AS distance_km
  FROM flights f
  JOIN coords        c1 ON c1.airport_code = f.departure_airport
  JOIN coords        c2 ON c2.airport_code = f.arrival_airport
  JOIN airports_data a1 ON a1.airport_code = f.departure_airport
  JOIN airports_data a2 ON a2.airport_code = f.arrival_airport
),
pairs AS (
  /* unique, unordered city pairs with the average distance over all their legs */
  SELECT
      CASE WHEN city1 < city2 THEN city1 ELSE city2 END  AS city_a,
      CASE WHEN city1 < city2 THEN city2 ELSE city1 END  AS city_b,
      AVG(distance_km)                                   AS avg_distance
  FROM legs
  GROUP BY city_a, city_b
),
bucketed AS (
  /* slot every pair into the requested distance buckets */
  SELECT
      CASE
          WHEN avg_distance < 1000 THEN '0'
          WHEN avg_distance < 2000 THEN '1000'
          WHEN avg_distance < 3000 THEN '2000'
          WHEN avg_distance < 4000 THEN '3000'
          WHEN avg_distance < 5000 THEN '4000'
          WHEN avg_distance < 6000 THEN '5000'
          ELSE '6000+'
      END                                               AS distance_range,
      COUNT(*)                                          AS pair_cnt
  FROM pairs
  GROUP BY distance_range
)
SELECT MIN(pair_cnt) AS fewest_city_pairs
FROM   bucketed;