WITH florida_zips AS (   -- all FL ZIP geo_ids present in the address table
    SELECT DISTINCT
           "ID_ZIP"                      AS "GEO_ID"
    FROM   US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE  "STATE" = 'FL'
),
zip_areas AS (           -- compute polygon area for those ZIPs
    SELECT
        gc."GEO_ID",
        ST_AREA(TO_GEOGRAPHY(gc."VALUE"))  AS "AREA_M2"
    FROM   US_ADDRESSES__POI.CYBERSYN.GEOGRAPHY_CHARACTERISTICS gc
    JOIN   florida_zips fz
           ON gc."GEO_ID" = fz."GEO_ID"
    WHERE  gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
),
largest_zip AS (         -- Florida ZIP with the largest geographic area
    SELECT  "GEO_ID"
    FROM    zip_areas
    ORDER BY "AREA_M2" DESC
    LIMIT   1
),
zip_addresses AS (       -- all addresses in that ZIP (restricted to FL)
    SELECT *
    FROM   US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES ua
    JOIN   largest_zip lz
           ON ua."ID_ZIP" = lz."GEO_ID"
    WHERE  ua."STATE" = 'FL'
      AND  ua."LATITUDE" IS NOT NULL
)
SELECT
    "NUMBER"        AS "ADDRESS_NUMBER",
    "STREET"        AS "STREET_NAME",
    "STREET_TYPE"
FROM   zip_addresses
ORDER BY
    "LATITUDE"  DESC NULLS LAST,
    "LONGITUDE" DESC NULLS LAST
LIMIT  10;