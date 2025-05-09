/*-----------------------------------------------------------
   1. Extract airport longitude / latitude and city names.
   2. Calculate the Haversine distance for every flight.
   3. Make the city-pair direction-independent and average
      the distances for each unique pair.
   4. Bucket the average distances.
   5. Count pairs in every bucket and return the smallest
      (i.e. the emptiest bucket’s size).
-----------------------------------------------------------*/
WITH airport_coords AS (
    SELECT
        "airport_code",
        /* coordinates text looks like '(lon,lat)' ----------------*/
        TRY_TO_DOUBLE(
            SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''), ',', 0)
        )::DOUBLE                                                    AS lon_deg,
        TRY_TO_DOUBLE(
            SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''), ',', 1)
        )::DOUBLE                                                    AS lat_deg,
        (PARSE_JSON("city"):en)::STRING                              AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
flight_distances AS (
    SELECT
        f."flight_id",
        dep.city_en                                                  AS dep_city,
        arr.city_en                                                  AS arr_city,
        RADIANS(dep.lat_deg)                                         AS lat1,
        RADIANS(arr.lat_deg)                                         AS lat2,
        RADIANS(dep.lon_deg)                                         AS lon1,
        RADIANS(arr.lon_deg)                                         AS lon2
    FROM AIRLINES.AIRLINES.FLIGHTS  f
    JOIN airport_coords dep ON dep."airport_code" = f."departure_airport"
    JOIN airport_coords arr ON arr."airport_code" = f."arrival_airport"
),
haversine AS (
    SELECT
        "flight_id",
        dep_city,
        arr_city,
        2 * 6371 * ASIN( SQRT(
              POWER(SIN((lat2 - lat1)/2), 2)
              + COS(lat1) * COS(lat2)
              * POWER(SIN((lon2 - lon1)/2), 2)
        ))                                                          AS distance_km
    FROM flight_distances
),
city_pair_avg AS (
    SELECT
        LEAST(dep_city, arr_city)                                   AS city1,
        GREATEST(dep_city, arr_city)                                AS city2,
        AVG(distance_km)                                            AS avg_distance_km
    FROM haversine
    GROUP BY 1, 2
),
bucketed_pairs AS (
    SELECT
        CASE
            WHEN avg_distance_km < 1000  THEN '0-1000'
            WHEN avg_distance_km < 2000  THEN '1000-2000'
            WHEN avg_distance_km < 3000  THEN '2000-3000'
            WHEN avg_distance_km < 4000  THEN '3000-4000'
            WHEN avg_distance_km < 5000  THEN '4000-5000'
            WHEN avg_distance_km < 6000  THEN '5000-6000'
            ELSE                               '6000+'
        END                                                        AS distance_range
    FROM city_pair_avg
),
range_counts AS (
    SELECT
        distance_range,
        COUNT(*)                                                    AS pair_cnt
    FROM bucketed_pairs
    GROUP BY distance_range
)
SELECT
    MIN(pair_cnt)                                                   AS min_pairs_in_emptiest_range
FROM range_counts;