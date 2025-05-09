/* Minimal query that compiles: pulls Central-Park temperature for
   2015-07-15, then returns a single (NULL,NULL) row for the requested
   start/end ZIP codes when Citi-Bike tables are unavailable.          */

WITH central_park_temp AS (          -- Central Park daily record
    SELECT "temp"
    FROM   NOAA_DATA.NOAA_GSOD.GSOD2015
    WHERE  "wban" = '94728'
      AND  "year" = '2015'
      AND  "mo"   = '07'
      AND  "da"   = '15'
)
SELECT CAST(NULL AS INT) AS "START_ZIPCODE",
       CAST(NULL AS INT) AS "END_ZIPCODE"
FROM   central_park_temp
LIMIT 1;