WITH
  airports AS (
    SELECT
      airport_code,
      TRIM(
        SUBSTR(
          city,
          INSTR(city, '"en": "') + 7,
          INSTR(city, '", "ru"') - (INSTR(city, '"en": "') + 7)
        )
      ) AS city_name_en,
      CAST(SUBSTR(coordinates, 2, INSTR(coordinates, ',') - 2) AS FLOAT) AS longitude,
      CAST(
        SUBSTR(
          coordinates,
          INSTR(coordinates, ',') + 1,
          LENGTH(coordinates) - INSTR(coordinates, ',') - 2
        ) AS FLOAT
      ) AS latitude
    FROM airports_data
  ),
  city_pair_distances AS (
    SELECT
      CASE
        WHEN ad.city_name_en <= aa.city_name_en THEN ad.city_name_en
        ELSE aa.city_name_en
      END AS city_a,
      CASE
        WHEN ad.city_name_en <= aa.city_name_en THEN aa.city_name_en
        ELSE ad.city_name_en
      END AS city_b,
      AVG(
        (
          (ad.latitude - aa.latitude) * (ad.latitude - aa.latitude) +
          ((ad.longitude - aa.longitude) * (ad.longitude - aa.longitude)) * 
          ( ( ((ad.latitude + aa.latitude) / 2.0) * 3.141592653589793 / 180.0 ) * ((ad.latitude + aa.latitude) / 2.0) * 3.141592653589793 / 180.0 )
        ) * 12392.22
      ) AS avg_distance_sq
    FROM flights f
    JOIN airports ad ON f.departure_airport = ad.airport_code
    JOIN airports aa ON f.arrival_airport = aa.airport_code
    GROUP BY city_a, city_b
  )
SELECT
  CASE
    WHEN avg_distance_sq <= 1000000 THEN '0-1000'
    WHEN avg_distance_sq <= 4000000 THEN '1000-2000'
    WHEN avg_distance_sq <= 9000000 THEN '2000-3000'
    WHEN avg_distance_sq <= 16000000 THEN '3000-4000'
    WHEN avg_distance_sq <= 25000000 THEN '4000-5000'
    WHEN avg_distance_sq <= 36000000 THEN '5000-6000'
    ELSE '6000+'
  END AS Distance_Range,
  COUNT(*) AS Number_of_City_Pairs
FROM city_pair_distances
GROUP BY Distance_Range
ORDER BY
  CASE
    WHEN avg_distance_sq <= 1000000 THEN 1
    WHEN avg_distance_sq <= 4000000 THEN 2
    WHEN avg_distance_sq <= 9000000 THEN 3
    WHEN avg_distance_sq <= 16000000 THEN 4
    WHEN avg_distance_sq <= 25000000 THEN 5
    WHEN avg_distance_sq <= 36000000 THEN 6
    ELSE 7
  END;