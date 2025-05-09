WITH fl_zip_ids AS (  -- all ZIP GEO_IDs that Florida (geoId/12) contains
    SELECT 
        r."RELATED_GEO_ID"      AS "ZIP_GEO_ID"
    FROM US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    WHERE r."GEO_ID"            = 'geoId/12'          -- Florida
      AND r."RELATIONSHIP_TYPE" = 'Contains'
      AND r."RELATED_LEVEL"     = 'CensusZipCodeTabulationArea'
),
zip_areas AS (         -- compute area of each ZIP polygon
    SELECT 
        g."GEO_ID"                                           AS "ZIP_GEO_ID",
        ST_AREA(TO_GEOGRAPHY(g."VALUE"))                     AS "AREA_SQM"
    FROM US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_CHARACTERISTICS g
    JOIN fl_zip_ids f
      ON g."GEO_ID" = f."ZIP_GEO_ID"
    WHERE g."RELATIONSHIP_TYPE" IN ('coordinates_wkt','coordinates_geojson')
),
largest_zip AS (       -- the single largest‑area ZIP in Florida
    SELECT 
        z."ZIP_GEO_ID"
    FROM zip_areas z
    ORDER BY z."AREA_SQM" DESC NULLS LAST
    LIMIT 1
),
largest_zip_code AS (  -- extract 5‑digit ZIP string
    SELECT 
        SUBSTR("ZIP_GEO_ID", 5) AS "ZIP_CODE"   -- removes 'zip/' prefix
    FROM largest_zip
)
SELECT
    a."NUMBER"        AS "ADDRESS_NUMBER",
    a."STREET"        AS "STREET_NAME",
    a."STREET_TYPE"   AS "STREET_TYPE"
FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES a
JOIN largest_zip_code z
  ON a."ZIP" = z."ZIP_CODE"
WHERE a."STATE" = 'FL'
ORDER BY a."LATITUDE" DESC NULLS LAST, a."LONGITUDE"  -- northernmost first, tie‑break by lon
LIMIT 10;