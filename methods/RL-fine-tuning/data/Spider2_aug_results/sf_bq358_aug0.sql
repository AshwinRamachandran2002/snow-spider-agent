-- Task: Find the starting and ending ZIP Codes of the bike trip in New York City on July 15, 2015, that started and ended in ZIP Code areas determined by the station coordinates, using the temperature data recorded by the Central Park weather station '94728' on that day. If there's more than one trip that meets these criteria, return the one associated with the highest recorded temperature for that day. If multiple trips still meet these criteria, select the one that starts in the smallest ZIP Code and ends in the largest ZIP Code.
SELECT
    "ZIPSTART"."zip_code" AS zip_code_start,
    "ZIPEND"."zip_code" AS zip_code_end
FROM  
    "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS" AS "TRI"
INNER JOIN
    "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" AS "ZIPSTART"
    ON ST_WITHIN(
        ST_POINT("TRI"."start_station_longitude", "TRI"."start_station_latitude"),
        ST_GEOGFROMWKB("ZIPSTART"."zip_code_geom")
    )
INNER JOIN
    "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" AS "ZIPEND"
    ON ST_WITHIN(
        ST_POINT("TRI"."end_station_longitude", "TRI"."end_station_latitude"),
        ST_GEOGFROMWKB("ZIPEND"."zip_code_geom")
    )
INNER JOIN
    "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2015" AS "WEA"
    ON TO_DATE(TO_CHAR("WEA"."year") || LPAD(TO_CHAR("WEA"."mo"), 2, '0') || LPAD(TO_CHAR("WEA"."da"), 2, '0'), 'YYYYMMDD') = DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."starttime") / 1000000))
WHERE
    "WEA"."wban" = '94728'
    AND DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."starttime") / 1000000)) = DATE '2015-07-15'
ORDER BY 
    "WEA"."temp" DESC, "ZIPSTART"."zip_code" ASC, "ZIPEND"."zip_code" DESC
LIMIT 1;