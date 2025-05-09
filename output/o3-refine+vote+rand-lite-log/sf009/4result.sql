/*---------------------------------------------------------------------------
  Building‑classification comparison for Amsterdam vs. Rotterdam
  ---------------------------------------------------------------------------
  1. city_boundaries  : pick the two municipal (admin_level = 8) polygons
  2. city_buildings   : buildings that spatially fall inside those polygons
  3. pivot            : side‑by‑side statistics for quick comparison
---------------------------------------------------------------------------*/
WITH city_boundaries AS (          -- step‑1 : obtain the municipal polygons
    SELECT
        CASE
            WHEN a."NAMES":"local"::string = 'Amsterdam'  THEN 'Amsterdam'
            WHEN a."NAMES":"local"::string = 'Rotterdam'  THEN 'Rotterdam'
        END                                    AS "CITY",
        a."GEO_CORDINATES"                     AS "GEOM"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ADMINISTRATIVE"  a
    WHERE a."ADMIN_LEVEL" = '8'
      AND a."NAMES":"local"::string IN ('Amsterdam','Rotterdam')
),

city_buildings AS (                -- step‑2 : buildings inside those polygons
    SELECT
        b."CLASS",
        b."SUBCLASS",
        c."CITY",
        SUM( TRY_TO_NUMBER( b."SURFACE_AREA_SQ_M" ) )          AS "TOTAL_SURFACE_AREA_SQ_M",
        COUNT(*)                                               AS "BUILDING_COUNT"
    FROM "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_BUILDING" b
    JOIN city_boundaries                                       c
          ON ST_INTERSECTS( b."GEO_CORDINATES", c."GEOM" )
    GROUP BY b."CLASS", b."SUBCLASS", c."CITY"
),

pivot AS (                        -- step‑3 : side‑by‑side pivot
    SELECT
        "CLASS",
        "SUBCLASS",
        SUM( CASE WHEN "CITY" = 'Amsterdam' THEN "TOTAL_SURFACE_AREA_SQ_M" END ) AS "AMS_TOTAL_SURFACE_AREA_SQ_M",
        SUM( CASE WHEN "CITY" = 'Amsterdam' THEN "BUILDING_COUNT"         END ) AS "AMS_BUILDING_COUNT",
        SUM( CASE WHEN "CITY" = 'Rotterdam' THEN "TOTAL_SURFACE_AREA_SQ_M" END ) AS "RTD_TOTAL_SURFACE_AREA_SQ_M",
        SUM( CASE WHEN "CITY" = 'Rotterdam' THEN "BUILDING_COUNT"         END ) AS "RTD_BUILDING_COUNT"
    FROM city_buildings
    GROUP BY "CLASS", "SUBCLASS"
)

SELECT *
FROM   pivot
ORDER  BY "CLASS" ASC NULLS LAST,
          "SUBCLASS" ASC NULLS LAST;