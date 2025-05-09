WITH hurricanes AS (
    SELECT
        "sid",
        "name",
        /* keep only valid coordinates so TO_GEOGRAPHY succeeds */
        TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')') AS h_geom
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND TRIM("name") <> ''
      AND "longitude" BETWEEN -180 AND 180
      AND "latitude"  BETWEEN  -90 AND  90
),
zip_codes AS (
    SELECT
        "city",
        "zip_code",
        "state_code",
        TO_GEOGRAPHY("zip_code_geom") AS z_geom
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
)
SELECT
    z."city",
    z."zip_code",
    z."state_code"                               AS "state",
    COUNT(DISTINCT h."sid")                      AS "hurricane_count",
    LISTAGG(DISTINCT h."name", ', ')
        WITHIN GROUP (ORDER BY h."name")         AS "hurricanes"
FROM zip_codes z
JOIN hurricanes h
  ON ST_WITHIN(h.h_geom, z.z_geom)
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    "hurricane_count" DESC NULLS LAST;