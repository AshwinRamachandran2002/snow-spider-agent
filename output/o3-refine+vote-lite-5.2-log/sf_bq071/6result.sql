SELECT
    z."city",
    z."zip_code",
    z."state_code"                         AS "state",
    COUNT(DISTINCT h."name")               AS "count_of_hurricanes",
    LISTAGG(DISTINCT h."name", ', ')
         WITHIN GROUP (ORDER BY h."name")  AS "hurricane_names"
FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES"  z
JOIN NOAA_DATA_PLUS.NOAA_HURRICANES."HURRICANES"   h
      /* keep only hurricanes with valid coordinates */
      ON  h."longitude" BETWEEN -180 AND 180
      AND h."latitude"  BETWEEN  -90 AND  90
      AND ST_WITHIN(
              TO_GEOGRAPHY('POINT(' || h."longitude" || ' ' || h."latitude" || ')'),
              TO_GEOGRAPHY(z."zip_code_geom")
          )
WHERE h."name" IS NOT NULL
  AND TRIM(h."name") <> ''
  AND UPPER(TRIM(h."name")) <> 'UNNAMED'
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    "count_of_hurricanes" DESC NULLS LAST,
    z."city",
    z."zip_code";