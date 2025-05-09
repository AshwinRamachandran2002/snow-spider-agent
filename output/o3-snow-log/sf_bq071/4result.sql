SELECT
    z."city",
    z."zip_code",
    z."state_code"                       AS "state",
    COUNT(DISTINCT h."sid")              AS "count_hurricanes",
    LISTAGG(DISTINCT h."name", ', ')
        WITHIN GROUP (ORDER BY h."name") AS "hurricane_names"
FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES"         z
JOIN NOAA_DATA_PLUS.NOAA_HURRICANES."HURRICANES"           h
  ON ST_CONTAINS(
         TO_GEOGRAPHY(z."zip_code_geom"),
         TO_GEOGRAPHY(ST_MAKEPOINT(h."longitude", h."latitude"))
     )
WHERE h."name" IS NOT NULL
  AND TRIM(h."name") <> ''                  -- exclude blank names
  AND UPPER(TRIM(h."name")) <> 'NOT_NAMED'  -- exclude unnamed storms
  AND h."longitude" BETWEEN -180 AND 180    -- ensure valid coordinates
  AND h."latitude"  BETWEEN  -90 AND  90
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    "count_hurricanes" DESC NULLS LAST;