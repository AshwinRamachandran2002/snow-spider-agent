SELECT
  CASE
    WHEN avg_distance_sq_km <= 1000000 THEN '0-1000'
    WHEN avg_distance_sq_km <= 4000000 THEN '1000-2000'
    WHEN avg_distance_sq_km <= 9000000 THEN '2000-3000'
    WHEN avg_distance_sq_km <= 16000000 THEN '3000-4000'
    WHEN avg_distance_sq_km <= 25000000 THEN '4000-5000'
    WHEN avg_distance_sq_km <= 36000000 THEN '5000-6000'
    ELSE '6000+'
  END AS Distance_Range,
  COUNT(*) AS Number_of_City_Pairs
FROM (
  SELECT
    departure_city,
    arrival_city,
    AVG(distance_sq_km) AS avg_distance_sq_km
  FROM (
    SELECT
      json_extract(dep.city, '$.en') AS departure_city,
      json_extract(arr.city, '$.en') AS arrival_city,
      (
        (
          CAST(SUBSTR(dep.coordinates, 2, INSTR(dep.coordinates, ',') - 2) AS REAL) -
          CAST(SUBSTR(arr.coordinates, 2, INSTR(arr.coordinates, ',') - 2) AS REAL)
        ) * (
          CAST(SUBSTR(dep.coordinates, 2, INSTR(dep.coordinates, ',') - 2) AS REAL) -
          CAST(SUBSTR(arr.coordinates, 2, INSTR(arr.coordinates, ',') - 2) AS REAL)
        ) +
        (
          CAST(SUBSTR(dep.coordinates, INSTR(dep.coordinates, ',') + 1, LENGTH(dep.coordinates) - INSTR(dep.coordinates, ',') - 1) AS REAL) -
          CAST(SUBSTR(arr.coordinates, INSTR(arr.coordinates, ',') + 1, LENGTH(arr.coordinates) - INSTR(arr.coordinates, ',') - 1) AS REAL)
        ) * (
          CAST(SUBSTR(dep.coordinates, INSTR(dep.coordinates, ',') + 1, LENGTH(dep.coordinates) - INSTR(dep.coordinates, ',') - 1) AS REAL) -
          CAST(SUBSTR(arr.coordinates, INSTR(arr.coordinates, ',') + 1, LENGTH(arr.coordinates) - INSTR(arr.coordinates, ',') - 1) AS REAL)
        )
      ) * 12321 AS distance_sq_km
    FROM flights AS f
    JOIN airports_data AS dep ON f.departure_airport = dep.airport_code
    JOIN airports_data AS arr ON f.arrival_airport = arr.airport_code
  ) AS distances
  GROUP BY departure_city, arrival_city
) AS city_pairs
GROUP BY Distance_Range
ORDER BY Number_of_City_Pairs ASC;