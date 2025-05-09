/*-----------------------------------------------------------------------
 Comprehensive building-classification comparison
   – Amsterdam vs. Rotterdam (surface area & #buildings)
------------------------------------------------------------------------*/
WITH city_boundaries AS (   -- pick the municipality polygons for the two cities
    SELECT
        CASE
            WHEN UPPER(TO_VARCHAR("NAMES")) LIKE '%AMSTERDAM%'  THEN 'Amsterdam'
            WHEN UPPER(TO_VARCHAR("NAMES")) LIKE '%ROTTERDAM%'  THEN 'Rotterdam'
        END                                             AS "CITY",
        "GEO_CORDINATES"                                AS "GEOM"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE
    WHERE  "ADMIN_LEVEL" = '8'      -- municipality level
      AND (UPPER(TO_VARCHAR("NAMES")) LIKE '%AMSTERDAM%'
           OR UPPER(TO_VARCHAR("NAMES")) LIKE '%ROTTERDAM%')
),

city_buildings AS (        -- buildings that fall inside either boundary
    SELECT
        b."CLASS",
        b."SUBCLASS",
        cb."CITY",
        COUNT(*)                                            AS "BUILDING_COUNT",
        SUM(TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M"))           AS "TOTAL_SURFACE_AREA_SQ_M"
    FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b
    JOIN   city_boundaries cb
           ON ST_CONTAINS(cb."GEOM", b."GEO_CORDINATES")
    GROUP  BY b."CLASS", b."SUBCLASS", cb."CITY"
),

pivoted AS (              -- convert rows per city into side-by-side columns
    SELECT
        "CLASS",
        "SUBCLASS",
        /* Amsterdam columns */
        SUM(CASE WHEN "CITY" = 'Amsterdam'
                 THEN "TOTAL_SURFACE_AREA_SQ_M" END)        AS "AMS_TOTAL_SURFACE_AREA_SQ_M",
        SUM(CASE WHEN "CITY" = 'Amsterdam'
                 THEN "BUILDING_COUNT" END)                 AS "AMS_BUILDING_COUNT",

        /* Rotterdam columns */
        SUM(CASE WHEN "CITY" = 'Rotterdam'
                 THEN "TOTAL_SURFACE_AREA_SQ_M" END)        AS "RTM_TOTAL_SURFACE_AREA_SQ_M",
        SUM(CASE WHEN "CITY" = 'Rotterdam'
                 THEN "BUILDING_COUNT" END)                 AS "RTM_BUILDING_COUNT"
    FROM   city_buildings
    GROUP  BY "CLASS", "SUBCLASS"
)

SELECT
    "CLASS",
    "SUBCLASS",
    "AMS_TOTAL_SURFACE_AREA_SQ_M",
    "AMS_BUILDING_COUNT",
    "RTM_TOTAL_SURFACE_AREA_SQ_M",
    "RTM_BUILDING_COUNT"
FROM   pivoted
ORDER  BY "CLASS" ASC, "SUBCLASS" ASC;