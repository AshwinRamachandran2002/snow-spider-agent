-- Task: List all flights along with their departure and arrival cities, and their coordinates (showing up to 100 records).
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
LIMIT 100;