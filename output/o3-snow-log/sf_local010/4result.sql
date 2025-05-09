WITH airports AS (
    SELECT
        "airport_code",
        TO_NUMBER(SPLIT_PART(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',', 1)) AS lon_deg,
        TO_NUMBER(SPLIT_PART(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',', 2)) AS lat_deg,
        PARSE_JSON("city"):en::string                                                  AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
flight_coords AS (
    SELECT
        f."flight_id",
        ad.city_en                                                                     AS dep_city,
        aa.city_en                                                                     AS arr_city,
        RADIANS(ad.lat_deg)                                                            AS lat1,
        RADIANS(aa.lat_deg)                                                            AS lat2,
        RADIANS(ad.lon_deg)                                                            AS lon1,
        RADIANS(aa.lon_deg)                                                            AS lon2
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airports ad ON f."departure_airport" = ad."airport_code"
    JOIN airports aa ON f."arrival_airport"   = aa."airport_code"
    WHERE ad.city_en IS NOT NULL
      AND aa.city_en IS NOT NULL
),
flight_distances AS (
    SELECT
        dep_city,
        arr_city,
        2 * 6371 * ASIN(
              SQRT(
                    POWER(SIN((lat2 - lat1) / 2), 2) +
                    COS(lat1) * COS(lat2) * POWER(SIN((lon2 - lon1) / 2), 2)
              )
        )                                                                              AS distance_km
    FROM flight_coords
),
city_pair_avg AS (
    SELECT
        LEAST(dep_city, arr_city)                                                     AS city1,
        GREATEST(dep_city, arr_city)                                                  AS city2,
        AVG(distance_km)                                                              AS avg_distance
    FROM flight_distances
    GROUP BY
        LEAST(dep_city, arr_city),
        GREATEST(dep_city, arr_city)
),
bucket_counts AS (
    SELECT
        CASE
            WHEN avg_distance < 1000 THEN '0'
            WHEN avg_distance < 2000 THEN '1000'
            WHEN avg_distance < 3000 THEN '2000'
            WHEN avg_distance < 4000 THEN '3000'
            WHEN avg_distance < 5000 THEN '4000'
            WHEN avg_distance < 6000 THEN '5000'
            ELSE '6000+'
        END                                                                            AS distance_range,
        COUNT(*)                                                                       AS pair_cnt
    FROM city_pair_avg
    GROUP BY distance_range
)
SELECT pair_cnt
FROM bucket_counts
ORDER BY pair_cnt ASC
LIMIT 1;