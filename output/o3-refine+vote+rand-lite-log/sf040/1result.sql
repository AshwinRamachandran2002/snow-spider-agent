WITH fl_zip_areas AS (   -- all FL ZIP polygons with calculated area
    SELECT
        gc."GEO_ID",
        SUBSTR(gc."GEO_ID", 5)          AS "ZIP",
        ST_AREA(ST_GEOGFROMTEXT(gc."VALUE")) AS "AREA_M2"
    FROM US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_CHARACTERISTICS AS gc
    JOIN US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_RELATIONSHIPS   AS gr
          ON gc."GEO_ID" = gr."GEO_ID"
    WHERE gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
      AND gc."GEO_ID" LIKE 'zip/%'               -- keep ZIP polygons only
      AND gr."RELATED_GEO_ID" = 'geoId/12'       -- Florida (state FIPS 12)
      AND gr."RELATIONSHIP_TYPE" = 'Overlaps'    -- ZIP overlaps Florida
), largest_fl_zip AS (   -- ZIP with the largest land area in Florida
    SELECT "ZIP"
    FROM fl_zip_areas
    ORDER BY "AREA_M2" DESC NULLS LAST
    LIMIT 1
), fl_addresses AS (     -- all addresses in that ZIP
    SELECT
        ua."NUMBER",
        ua."STREET",
        ua."STREET_TYPE",
        ua."LATITUDE",
        ua."LONGITUDE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES AS ua
    JOIN largest_fl_zip lz
          ON ua."ZIP" = lz."ZIP"
    WHERE ua."LATITUDE" IS NOT NULL
)
SELECT
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM fl_addresses
ORDER BY "LATITUDE" DESC NULLS LAST, "LONGITUDE" DESC NULLS LAST   -- northernmost first
LIMIT 10;