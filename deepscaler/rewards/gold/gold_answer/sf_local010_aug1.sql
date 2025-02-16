-- Task: Calculate the average distance of all flights between each unique pair of cities. Limit the result to 100 rows.

WITH FLIGHT_INFO AS (
    SELECT    
        FLIGHTS."flight_id",
        PARSE_JSON(DEPARTURE."city"):"en" AS "from_city",
        CAST(SUBSTR(DEPARTURE."coordinates", 2, POSITION(',' IN DEPARTURE."coordinates") - 2) AS DOUBLE) AS "from_longitude",
        CAST(SUBSTR(DEPARTURE."coordinates", POSITION(',' IN DEPARTURE."coordinates") + 1, LENGTH(DEPARTURE."coordinates") - POSITION(',' IN DEPARTURE."coordinates") - 2) AS DOUBLE) AS "from_latitude",
        PARSE_JSON(ARRIVAL."city"):"en" AS "to_city",
        CAST(SUBSTR(ARRIVAL."coordinates", 2, POSITION(',' IN ARRIVAL."coordinates") - 2) AS DOUBLE) AS "to_longitude",
        CAST(SUBSTR(ARRIVAL."coordinates", POSITION(',' IN ARRIVAL."coordinates") + 1, LENGTH(ARRIVAL."coordinates") - POSITION(',' IN ARRIVAL."coordinates") - 2) AS DOUBLE) AS "to_latitude"
    FROM
        AIRLINES.AIRLINES.FLIGHTS 
    LEFT JOIN AIRLINES.AIRLINES.AIRPORTS_DATA AS DEPARTURE ON FLIGHTS."departure_airport" = DEPARTURE."airport_code"
    LEFT JOIN AIRLINES.AIRLINES.AIRPORTS_DATA AS ARRIVAL ON FLIGHTS."arrival_airport" = ARRIVAL."airport_code"
)
SELECT
    "from_city",
    "to_city",
    AVG("distance_km") AS "average_distance_km"
FROM (
    SELECT
        "from_city",
        "to_city",
        -- Calculate the distance using the Haversine formula
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(("to_latitude" - "from_latitude") / 2)), 2) +
            COS(RADIANS("from_latitude")) * COS(RADIANS("to_latitude")) *
            POWER(SIN(RADIANS(("to_longitude" - "from_longitude") / 2)), 2)
        )) AS "distance_km"
    FROM FLIGHT_INFO
) AS subquery
GROUP BY "from_city", "to_city"
LIMIT 100