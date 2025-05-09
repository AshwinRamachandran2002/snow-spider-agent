/*  Hurricanes that fell inside each ZIP‑code polygon
    -------------------------------------------------
    • Exclude points with blank name or placeholder 'NOT_NAMED'.
    • Build a GEOGRAPHY point for every valid storm observation,
      normalising longitudes that are reported on the 0‑360 scale.
    • Test the point against the ZIP polygon with ST_WITHIN.
    • Aggregate distinct hurricane names per (city, ZIP, state),
      list them alphabetically, and sort by the count descending. */
WITH hurricanes_geog AS (
    SELECT
        "sid",
        "name",
        TO_GEOGRAPHY(
            ST_MAKEPOINT(
                CASE
                    WHEN "longitude" >  180 THEN "longitude" - 360
                    WHEN "longitude" < -180 THEN "longitude" + 360
                    ELSE "longitude"
                END,
                "latitude"
            )
        ) AS "geom"
    FROM "NOAA_DATA_PLUS"."NOAA_HURRICANES"."HURRICANES"
    WHERE "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND TRIM("name") <> ''
      AND UPPER("name") <> 'NOT_NAMED'
),
zip_codes_geog AS (
    SELECT
        "city",
        "zip_code",
        "state_code",
        TO_GEOGRAPHY("zip_code_geom") AS "geom"
    FROM "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES"
    WHERE "zip_code_geom" IS NOT NULL
)
SELECT
    z."city"                                   AS city,
    z."zip_code"                               AS zip_code,
    z."state_code"                             AS state,
    COUNT(DISTINCT h."name")                   AS count_of_hurricanes,
    LISTAGG(DISTINCT h."name", ', ')
        WITHIN GROUP (ORDER BY h."name")       AS hurricanes
FROM zip_codes_geog z
JOIN hurricanes_geog h
  ON ST_WITHIN(h."geom", z."geom")
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    count_of_hurricanes DESC NULLS LAST,
    z."city";