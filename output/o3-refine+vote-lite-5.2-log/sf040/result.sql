/*  1. Identify every ZIP that “Overlaps” the State of Florida (geoId/12)
    2. Compute the surface area (in m²) for each of those ZIP polygons
       by converting the WKT string to a GEOGRAPHY object and using ST_AREA
    3. Pick the single largest‑area Florida ZIP
    4. Pull every address that belongs to that ZIP
    5. Return the 10 addresses having the greatest (northern‑most) latitude   */

WITH fl_zips AS (  -- Florida ZIP codes
    SELECT DISTINCT gr."GEO_ID"
    FROM US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    WHERE gr."GEO_ID"            LIKE 'zip/%'
      AND gr."RELATED_GEO_ID"    = 'geoId/12'          -- Florida
      AND gr."RELATIONSHIP_TYPE" = 'Overlaps'
),

zip_areas AS (     -- area of each ZIP (m²)
    SELECT
        gc."GEO_ID",
        ST_AREA(TO_GEOGRAPHY(gc."VALUE")) AS "AREA_M2"
    FROM US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_CHARACTERISTICS gc
    JOIN fl_zips fz
      ON gc."GEO_ID" = fz."GEO_ID"
    WHERE gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
),

largest_zip AS (   -- the single largest Florida ZIP by area
    SELECT "GEO_ID"
    FROM zip_areas
    ORDER BY "AREA_M2" DESC NULLS LAST
    LIMIT 1
),

zip_addresses AS ( -- all addresses within that ZIP
    SELECT
        ua."LATITUDE",
        ua."NUMBER"       AS "ADDRESS_NUMBER",
        ua."STREET"       AS "STREET_NAME",
        ua."STREET_TYPE"  AS "STREET_TYPE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES ua
    JOIN largest_zip lz
      ON ua."ID_ZIP" = lz."GEO_ID"
)

SELECT
    "ADDRESS_NUMBER",
    "STREET_NAME",
    "STREET_TYPE"
FROM zip_addresses
ORDER BY "LATITUDE" DESC NULLS LAST, "ADDRESS_NUMBER"
LIMIT 10;