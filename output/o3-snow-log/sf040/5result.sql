WITH fl_zip_areas AS (
    /* 1.  All Florida ZIP polygons with their geospatial area */
    SELECT
        gc."GEO_ID",                               /* e.g., zip/33101      */
        ST_AREA(TO_GEOGRAPHY(gc."VALUE")) AS "AREA"
    FROM US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_CHARACTERISTICS"  gc
    JOIN US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_RELATIONSHIPS"    gr
          ON gc."GEO_ID" = gr."GEO_ID"
    WHERE gc."RELATIONSHIP_TYPE" = 'coordinates_wkt'
      AND gc."GEO_ID"            LIKE 'zip/%'      /* limit to ZIPs        */
      AND gr."RELATED_GEO_ID"    = 'geoId/12'      /* Florida GEO_ID       */
      AND gr."RELATIONSHIP_TYPE" = 'Overlaps'      /* ZIP lies in Florida  */
),
largest_fl_zip AS (
    /* 2.  Identify Florida’s largest-area ZIP code */
    SELECT "GEO_ID"  AS "ID_ZIP"
    FROM   fl_zip_areas
    ORDER  BY "AREA" DESC NULLS LAST
    LIMIT  1
)
SELECT  ua."NUMBER"       AS "ADDRESS_NUMBER",
        ua."STREET"       AS "STREET_NAME",
        ua."STREET_TYPE"  AS "STREET_TYPE"
FROM    US_ADDRESSES__POI.CYBERSYN."US_ADDRESSES"  ua
JOIN    largest_fl_zip  lz
          ON ua."ID_ZIP" = lz."ID_ZIP"
WHERE   ua."LATITUDE" IS NOT NULL                 /* ensure valid coords  */
ORDER BY ua."LATITUDE" DESC NULLS LAST            /* northernmost first   */
LIMIT  10;                                         /* top 10 addresses     */