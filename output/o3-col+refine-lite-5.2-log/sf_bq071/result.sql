/*  Hurricanes that occur inside each ZIP‐code polygon.
    - Longitude values > 180 are shifted westward by subtracting 360, so ST_WITHIN accepts them.
    - Unnamed storms are filtered out (NULL, blank, or literally “UNNAMED”).
    - The hurricane name list is de‑duplicated, alphabetised, and returned as a
      comma‑separated string.
*/
WITH hurricanes_geo AS (   -- build a GEOGRAPHY point for every valid, named hurricane record
    SELECT
        TRIM("name")                          AS storm_name,
        TO_GEOGRAPHY(
            'POINT(' ||
            CASE
                WHEN "longitude" > 180 THEN "longitude" - 360
                ELSE "longitude"
            END || ' ' || "latitude" || ')'
        )                                     AS storm_point
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND TRIM("name") <> ''
      AND UPPER(TRIM("name")) <> 'UNNAMED'
)
SELECT
    z."city",
    z."zip_code",
    z."state_code"                        AS state,
    COUNT(*)                              AS hurricane_count,
    ARRAY_TO_STRING(
        ARRAY_SORT(                       -- alphabetise
            ARRAY_AGG(DISTINCT h.storm_name)
        ),
        ', '
    )                                     AS hurricane_list
FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES AS z
JOIN hurricanes_geo AS h
  ON ST_WITHIN(
        h.storm_point,
        TO_GEOGRAPHY(z."zip_code_geom")
     )
GROUP BY
    z."city",
    z."zip_code",
    z."state_code"
ORDER BY
    hurricane_count DESC NULLS LAST,
    z."zip_code"
;