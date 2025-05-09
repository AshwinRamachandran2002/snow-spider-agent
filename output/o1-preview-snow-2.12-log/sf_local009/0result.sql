WITH
  Abakan_Coordinates AS (
    SELECT
      ST_GeogFromText('POINT(' || 
        SPLIT_PART(SUBSTR("coordinates", 2, LENGTH("coordinates") - 2), ',', 1) || ' ' ||
        SPLIT_PART(SUBSTR("coordinates", 2, LENGTH("coordinates") - 2), ',', 2) || ')'
      ) AS aba_point
    FROM
      "AIRLINES"."AIRLINES"."AIRPORTS_DATA"
    WHERE
      "airport_code" = 'ABA'
  ),
  Connected_Airports AS (
    SELECT DISTINCT
      CASE
        WHEN F."departure_airport" = 'ABA' THEN F."arrival_airport"
        ELSE F."departure_airport"
      END AS connected_airport
    FROM
      "AIRLINES"."AIRLINES"."FLIGHTS" AS F
    WHERE
      F."departure_airport" = 'ABA'
      OR F."arrival_airport" = 'ABA'
  ),
  Connected_Airport_Coordinates AS (
    SELECT
      CA.connected_airport,
      PARSE_JSON(AD."city"):"en"::STRING AS connected_city,
      ST_GeogFromText('POINT(' ||
        SPLIT_PART(SUBSTR(AD."coordinates", 2, LENGTH(AD."coordinates") - 2), ',', 1) || ' ' ||
        SPLIT_PART(SUBSTR(AD."coordinates", 2, LENGTH(AD."coordinates") - 2), ',', 2) || ')'
      ) AS conn_point
    FROM
      Connected_Airports AS CA
      JOIN "AIRLINES"."AIRLINES"."AIRPORTS_DATA" AS AD ON CA.connected_airport = AD."airport_code"
  ),
  Distances AS (
    SELECT
      CAC.connected_city AS City,
      ST_Distance(AC.aba_point, CAC.conn_point) / 1000 AS Distance_km
    FROM
      Abakan_Coordinates AS AC,
      Connected_Airport_Coordinates AS CAC
  )
SELECT
  City,
  ROUND(Distance_km, 4) AS Distance_km
FROM
  Distances
ORDER BY
  Distance_km DESC NULLS LAST
LIMIT
  1;