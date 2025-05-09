SELECT
    z."city"                                         AS "city",
    z."zip_code"                                     AS "zip_code",
    z."state_code"                                   AS "state",
    ARRAY_SIZE(ARRAY_AGG(DISTINCT h."name"))         AS "count_of_hurricanes",
    ARRAY_TO_STRING(
        ARRAY_SORT(ARRAY_AGG(DISTINCT h."name")),
        ', '
    )                                                AS "hurricanes"
FROM (
    SELECT *
    FROM "NOAA_DATA_PLUS"."NOAA_HURRICANES"."HURRICANES"
    WHERE "name" IS NOT NULL
      AND TRIM("name") <> ''
      AND UPPER("name") <> 'NOT_NAMED'          -- exclude unnamed hurricanes
      AND "longitude" BETWEEN -180 AND 180      -- ensure valid longitude
      AND "latitude"  BETWEEN  -90 AND  90      -- ensure valid latitude
) h
JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
  ON ST_WITHIN(
       ST_POINT(h."longitude", h."latitude"),
       TO_GEOGRAPHY(z."zip_code_geom")
     )
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    "count_of_hurricanes" DESC NULLS LAST,
    z."city" ASC;