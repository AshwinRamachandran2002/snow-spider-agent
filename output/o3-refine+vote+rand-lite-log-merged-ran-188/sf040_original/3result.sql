WITH fl_zip_codes AS (  -- every ZIP (CZCTA) that Florida contains
    SELECT r."RELATED_GEO_ID" AS "ZIP_GEO_ID"
    FROM "US_ADDRESSES__POI"."CYBERSYN"."GEOGRAPHY_RELATIONSHIPS" r
    WHERE r."GEO_ID" = 'geoId/12'                       -- Florida
      AND r."RELATIONSHIP_TYPE" = 'Contains'
      AND r."RELATED_LEVEL" = 'CensusZipCodeTabulationArea'
),                                                         
zip_areas AS (  -- compute area of each Florida ZIP
    SELECT f."ZIP_GEO_ID",
           ST_AREA(TO_GEOGRAPHY(gc."VALUE")) AS "AREA_M2"
    FROM fl_zip_codes f
    JOIN "US_ADDRESSES__POI"."CYBERSYN"."GEOGRAPHY_CHARACTERISTICS" gc
      ON gc."GEO_ID" = f."ZIP_GEO_ID"
     AND gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
),                                                         
largest_fl_zip AS (  -- pick the largest‐area ZIP in Florida
    SELECT "ZIP_GEO_ID"
    FROM zip_areas
    ORDER BY "AREA_M2" DESC NULLS LAST
    LIMIT 1
),                                                         
addresses_in_largest_zip AS (  -- all addresses in that ZIP
    SELECT a."NUMBER",
           a."STREET",
           a."STREET_TYPE",
           a."LATITUDE"
    FROM "US_ADDRESSES__POI"."CYBERSYN"."US_ADDRESSES" a
    JOIN largest_fl_zip l
      ON a."ID_ZIP" = l."ZIP_GEO_ID"
    WHERE a."LATITUDE" IS NOT NULL
)                                                          
-- 10 northern‑most addresses in the ZIP
SELECT "NUMBER"        AS "ADDRESS_NUMBER",
       "STREET"        AS "STREET_NAME",
       "STREET_TYPE"
FROM addresses_in_largest_zip
ORDER BY "LATITUDE" DESC NULLS LAST,
         "ADDRESS_NUMBER"
LIMIT 10;