WITH hurricane_points AS (
    SELECT
        TRIM("name")                                                   AS HURRICANE_NAME,
        TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')') AS GEOM
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND TRIM("name") <> ''
      AND UPPER(TRIM("name")) NOT IN ('UNNAMED', 'UNKNOWN', 'NOT NAMED')
      -- keep only valid coordinate ranges
      AND "longitude" BETWEEN -180 AND 180
      AND "latitude"  BETWEEN  -90 AND  90
),
zip_polygons AS (
    SELECT
        "zip_code"                                   AS ZIP_CODE,
        "city"                                       AS CITY,
        "state_code"                                 AS STATE,
        TO_GEOGRAPHY("zip_code_geom")                AS GEOM
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
)

SELECT
    z.CITY,
    z.ZIP_CODE,
    z.STATE,
    COUNT(DISTINCT h.HURRICANE_NAME)                                       AS HURRICANE_COUNT,
    LISTAGG(DISTINCT h.HURRICANE_NAME, ', ')
        WITHIN GROUP (ORDER BY h.HURRICANE_NAME)                           AS HURRICANE_NAMES
FROM zip_polygons z
JOIN hurricane_points h
  ON ST_WITHIN(h.GEOM, z.GEOM)
GROUP BY
    z.CITY,
    z.ZIP_CODE,
    z.STATE
ORDER BY
    HURRICANE_COUNT DESC NULLS LAST;