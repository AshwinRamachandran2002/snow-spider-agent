WITH coords AS (
    SELECT  "airport_code",
            CAST(SUBSTR("coordinates", 2,
                        INSTR("coordinates", ',') - 2)                    AS REAL) AS lon,
            CAST(SUBSTR("coordinates",
                        INSTR("coordinates", ',') + 1,
                        INSTR("coordinates", ')') - INSTR("coordinates", ',') - 1)
                        AS REAL)                                         AS lat,
            json_extract("city", '$.en')                                 AS city_en
    FROM    "airports_data"
),
dists AS (
    SELECT  CASE WHEN dep.city_en < arr.city_en THEN dep.city_en ELSE arr.city_en END AS city_a,
            CASE WHEN dep.city_en < arr.city_en THEN arr.city_en ELSE dep.city_en END AS city_b,
            6371 *
            ACOS( SIN(dep.lat*3.141592653589793/180) * SIN(arr.lat*3.141592653589793/180) +
                  COS(dep.lat*3.141592653589793/180) * COS(arr.lat*3.141592653589793/180) *
                  COS((arr.lon-dep.lon)*3.141592653589793/180) )         AS distance_km
    FROM    "flights"        AS f
    JOIN    coords           AS dep ON dep."airport_code" = f."departure_airport"
    JOIN    coords           AS arr ON arr."airport_code" = f."arrival_airport"
),
avg_pair AS (
    SELECT  city_a,
            city_b,
            AVG(distance_km) AS avg_distance
    FROM    dists
    GROUP BY city_a, city_b
),
bucketed AS (
    SELECT  CASE
              WHEN avg_distance < 1000 THEN '0-999'
              WHEN avg_distance < 2000 THEN '1000-1999'
              WHEN avg_distance < 3000 THEN '2000-2999'
              WHEN avg_distance < 4000 THEN '3000-3999'
              WHEN avg_distance < 5000 THEN '4000-4999'
              WHEN avg_distance < 6000 THEN '5000-5999'
              ELSE '6000+'
            END                                                   AS bucket
    FROM    avg_pair
),
bucket_counts AS (
    SELECT  bucket,
            COUNT(*) AS pair_count
    FROM    bucketed
    GROUP BY bucket
)
SELECT  pair_count
FROM    bucket_counts
WHERE   pair_count = (SELECT MIN(pair_count) FROM bucket_counts);