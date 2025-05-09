SELECT
    ZIP."city"                                   AS "city",
    ZIP."zip_code"                               AS "zip_code",
    ZIP."state_code"                             AS "state",
    COUNT(DISTINCT HUR."sid")                    AS "count_of_hurricanes",
    LISTAGG(DISTINCT HUR."name", ', ')
        WITHIN GROUP (ORDER BY HUR."name")       AS "hurricanes"
FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES"   AS ZIP
JOIN NOAA_DATA_PLUS.NOAA_HURRICANES."HURRICANES"    AS HUR
      ON HUR."latitude"  BETWEEN -90  AND  90
     AND HUR."longitude" BETWEEN -180 AND 180
     AND ST_WITHIN(
           ST_MAKEPOINT(HUR."longitude", HUR."latitude"),
           TO_GEOGRAPHY(ZIP."zip_code_geom")
         )
WHERE HUR."name" IS NOT NULL
  AND TRIM(HUR."name") <> ''
  AND UPPER(TRIM(HUR."name")) NOT IN ('UNNAMED', 'NOT_NAMED')
GROUP BY
    ZIP."city",
    ZIP."zip_code",
    ZIP."state_code"
ORDER BY
    "count_of_hurricanes" DESC NULLS LAST,
    ZIP."zip_code";