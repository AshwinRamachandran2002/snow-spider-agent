WITH airport_coords AS (
    SELECT
        "airport_code",
        TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("coordinates",'\\(|\\)',''),',',1))                      AS longitude,
        TO_DOUBLE(SPLIT_PART(REGEXP_REPLACE("coordinates",'\\(|\\)',''),',',2))                      AS latitude,
        PARSE_JSON("city"):"en"::STRING                                                              AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
flight_cities AS (
    SELECT
        f."flight_id",
        dep.city_en                                      AS dep_city,
        arr.city_en                                      AS arr_city,
        dep.latitude                                     AS dep_lat,
        dep.longitude                                    AS dep_lon,
        arr.latitude                                     AS arr_lat,
        arr.longitude                                    AS arr_lon
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airport_coords dep ON f."departure_airport" = dep."airport_code"
    JOIN airport_coords arr ON f."arrival_airport"   = arr."airport_code"
),
distances AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        2*6371*ASIN(
            SQRT(
                POWER(SIN(RADIANS(arr_lat - dep_lat)/2),2) +
                COS(RADIANS(dep_lat))*COS(RADIANS(arr_lat))*
                POWER(SIN(RADIANS(arr_lon - dep_lon)/2),2)
            )
        ) AS distance_km
    FROM flight_cities
),
avg_distances AS (
    SELECT
        city1,
        city2,
        AVG(distance_km) AS avg_distance
    FROM distances
    GROUP BY city1, city2
),
bins AS (
    SELECT * FROM VALUES
        (0   , '0-999'      ),
        (1000, '1000-1999'  ),
        (2000, '2000-2999'  ),
        (3000, '3000-3999'  ),
        (4000, '4000-4999'  ),
        (5000, '5000-5999'  ),
        (6000, '6000+'      )
    AS t(bin_start, range_label)
),
pair_bins AS (
    SELECT
        b.range_label,
        COUNT(d.avg_distance) AS pair_count
    FROM bins b
    LEFT JOIN avg_distances d
           ON ( (b.bin_start = 6000  AND d.avg_distance >= 6000)
             OR (b.bin_start < 6000 AND d.avg_distance >= b.bin_start AND d.avg_distance < b.bin_start + 1000)
              )
    GROUP BY b.range_label
)
SELECT MIN(pair_count) AS min_pair_count_in_weakest_range
FROM pair_bins;