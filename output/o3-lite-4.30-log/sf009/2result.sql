WITH city_boundaries AS (   -- select municipality polygons for Amsterdam and Rotterdam
    SELECT
        CASE
            WHEN LOWER(f.value::STRING) = 'amsterdam' THEN 'Amsterdam'
            WHEN LOWER(f.value::STRING) = 'rotterdam' THEN 'Rotterdam'
        END                                   AS "CITY",
        a."GEO_CORDINATES"                    AS "GEOM"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE a,
         LATERAL FLATTEN (INPUT => a."NAMES") f
    WHERE a."ADMIN_LEVEL" = '8'
      AND LOWER(f.value::STRING) IN ('amsterdam','rotterdam')
),
city_union AS (             -- dissolve possibly multiple parts per city
    SELECT
        "CITY",
        ST_UNION_AGG("GEOM") AS "CITY_GEOM"
    FROM city_boundaries
    GROUP BY "CITY"
),
buildings_tagged AS (       -- keep buildings that fall inside either city and label them
    SELECT
        b."CLASS"                                      AS "BUILDING_CLASS",
        b."SUBCLASS"                                   AS "BUILDING_SUBCLASS",
        TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")           AS "SURFACE",
        CASE
            WHEN ST_INTERSECTS(
                     b."GEO_CORDINATES",
                     (SELECT "CITY_GEOM" FROM city_union WHERE "CITY" = 'Amsterdam')
                 ) THEN 'Amsterdam'
            WHEN ST_INTERSECTS(
                     b."GEO_CORDINATES",
                     (SELECT "CITY_GEOM" FROM city_union WHERE "CITY" = 'Rotterdam')
                 ) THEN 'Rotterdam'
        END                                            AS "CITY"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING b
    WHERE   ST_INTERSECTS(b."GEO_CORDINATES",
                          (SELECT "CITY_GEOM" FROM city_union WHERE "CITY" = 'Amsterdam'))
        OR ST_INTERSECTS(b."GEO_CORDINATES",
                          (SELECT "CITY_GEOM" FROM city_union WHERE "CITY" = 'Rotterdam'))
),
city_agg AS (               -- aggregate by class/subclass per city
    SELECT
        "BUILDING_CLASS",
        "BUILDING_SUBCLASS",
        "CITY",
        COUNT(*)                               AS "TOTAL_BUILDINGS",
        ROUND(SUM("SURFACE"), 4)               AS "TOTAL_SURFACE_SQM"
    FROM buildings_tagged
    GROUP BY "BUILDING_CLASS", "BUILDING_SUBCLASS", "CITY"
)
SELECT
    "BUILDING_CLASS"                                                                 AS building_class,
    "BUILDING_SUBCLASS"                                                              AS building_subclass,
    COALESCE(MAX(CASE WHEN "CITY" = 'Amsterdam' THEN "TOTAL_SURFACE_SQM" END), 0)    AS amsterdam_total_surface_sqm,
    COALESCE(MAX(CASE WHEN "CITY" = 'Amsterdam' THEN "TOTAL_BUILDINGS"   END), 0)    AS amsterdam_total_buildings,
    COALESCE(MAX(CASE WHEN "CITY" = 'Rotterdam' THEN "TOTAL_SURFACE_SQM" END), 0)    AS rotterdam_total_surface_sqm,
    COALESCE(MAX(CASE WHEN "CITY" = 'Rotterdam' THEN "TOTAL_BUILDINGS"   END), 0)    AS rotterdam_total_buildings
FROM city_agg
GROUP BY
    "BUILDING_CLASS",
    "BUILDING_SUBCLASS"
ORDER BY
    "BUILDING_CLASS",
    "BUILDING_SUBCLASS";