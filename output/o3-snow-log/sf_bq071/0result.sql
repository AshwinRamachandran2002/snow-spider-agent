SELECT
    z."city",
    z."zip_code",
    z."state_code"                             AS "state",
    COUNT(DISTINCT h."name")                   AS "hurricane_cnt",
    LISTAGG(DISTINCT h."name", ', ')
        WITHIN GROUP (ORDER BY h."name")       AS "hurricanes"
FROM NOAA_DATA_PLUS.NOAA_HURRICANES."HURRICANES"     h
JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES"    z
  ON ST_CONTAINS(
       ST_GEOGFROMWKB(z."zip_code_geom"),            -- ZIP polygon
       ST_POINT(h."longitude", h."latitude")         -- hurricane location
     )
WHERE h."longitude" BETWEEN -180 AND 180             -- ensure valid coords
  AND h."latitude"  BETWEEN  -90 AND  90
  AND h."name" IS NOT NULL                           -- exclude NULL names
  AND TRIM(h."name") <> ''                           -- exclude blank names
  AND UPPER(TRIM(h."name")) <> 'NOT_NAMED'           -- exclude “unnamed” storms
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    "hurricane_cnt" DESC NULLS LAST;