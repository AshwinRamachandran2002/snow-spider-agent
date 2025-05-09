WITH abakan_airports AS (          -- Abakan airport(s)
    SELECT  "airport_code"
    FROM    AIRLINES.AIRLINES.AIRPORTS_DATA
    WHERE   LOWER(PARSE_JSON("city"):en::STRING) = 'abakan'
        OR  LOWER(PARSE_JSON("city"):ru::STRING) = 'абакан'
),

abba_flights AS (                  -- flights where Abakan is origin or destination
    SELECT  f."flight_id",
            f."departure_airport"      AS dep_code,
            f."arrival_airport"        AS arr_code
    FROM    AIRLINES.AIRLINES.FLIGHTS f
    JOIN    abakan_airports a
           ON f."departure_airport" = a."airport_code"
           OR f."arrival_airport"   = a."airport_code"
),

coords AS (                         -- add coordinates for both airports
    SELECT  bf.*,
            ad_dep."coordinates"  AS dep_coord,
            ad_arr."coordinates"  AS arr_coord
    FROM    abba_flights bf
    JOIN    AIRLINES.AIRLINES.AIRPORTS_DATA ad_dep
           ON bf.dep_code = ad_dep."airport_code"
    JOIN    AIRLINES.AIRLINES.AIRPORTS_DATA ad_arr
           ON bf.arr_code = ad_arr."airport_code"
),

nums AS (                           -- convert coordinate strings to numbers
    SELECT  *,
            SPLIT_PART(REPLACE(REPLACE(dep_coord,'(', ''),')',''),',',1)::FLOAT  AS dep_lon_deg,
            SPLIT_PART(REPLACE(REPLACE(dep_coord,'(', ''),')',''),',',2)::FLOAT  AS dep_lat_deg,
            SPLIT_PART(REPLACE(REPLACE(arr_coord,'(', ''),')',''),',',1)::FLOAT  AS arr_lon_deg,
            SPLIT_PART(REPLACE(REPLACE(arr_coord,'(', ''),')',''),',',2)::FLOAT  AS arr_lat_deg
    FROM    coords
),

distances AS (                      -- Haversine distance in km
    SELECT  "flight_id",
            2 * 6371 * ASIN( SQRT(
                    POWER(SIN( (RADIANS(arr_lat_deg) - RADIANS(dep_lat_deg)) / 2 ),2) +
                    COS(RADIANS(dep_lat_deg)) * COS(RADIANS(arr_lat_deg)) *
                    POWER(SIN( (RADIANS(arr_lon_deg) - RADIANS(dep_lon_deg)) / 2 ),2)
            ))  AS distance_km
    FROM    nums
)

SELECT  MAX(distance_km)  AS longest_distance_km
FROM    distances;