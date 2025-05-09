WITH florida_zips AS (   -- ZIP‐codes that overlap the State of Florida
    SELECT DISTINCT
           gr."GEO_ID"                      AS zip_geo_id,
           SUBSTR(gr."GEO_ID", 5)           AS zip_code          -- strip the `zip/` prefix
    FROM   US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    WHERE  gr."LEVEL"              = 'CensusZipCodeTabulationArea'
      AND  gr."RELATED_GEO_ID"     = 'geoId/12'                 -- Florida (FIPS 12)
      AND  gr."RELATIONSHIP_TYPE"  = 'Overlaps'
),
zip_areas AS (          -- Compute surface area (m²) of every Florida ZIP
    SELECT
           fz.zip_geo_id,
           fz.zip_code,
           ST_AREA(TO_GEOGRAPHY(gc."VALUE")) AS area_m2
    FROM   florida_zips fz
    JOIN   US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_CHARACTERISTICS gc
           ON gc."GEO_ID" = fz.zip_geo_id
          AND gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
),
largest_zip AS (        -- The single largest ZIP by geographic area
    SELECT  zip_code
    FROM    zip_areas
    ORDER BY area_m2 DESC NULLS LAST
    LIMIT   1
),
target_addresses AS (   -- All addresses inside that ZIP
    SELECT
           ua."NUMBER"       AS address_number,
           ua."STREET"       AS street_name,
           ua."STREET_TYPE"  AS street_type,
           ua."LATITUDE"
    FROM   US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES ua
    JOIN   largest_zip lz
           ON ua."ZIP" = lz.zip_code
    WHERE  ua."STATE" = 'FL'
      AND  ua."LATITUDE" IS NOT NULL
)
SELECT
       address_number,
       street_name,
       street_type
FROM   target_addresses
ORDER BY LATITUDE DESC NULLS LAST, address_number   -- northernmost first
LIMIT 10;