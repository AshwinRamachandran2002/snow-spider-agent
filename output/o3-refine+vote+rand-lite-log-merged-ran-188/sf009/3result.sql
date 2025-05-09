/* ---------------------------------------------------------------------------
   Building class/sub-class comparison between Amsterdam and Rotterdam
   ---------------------------------------------------------------------------
   – Amsterdam municipality  : administrative feature ID 'r47811@69'
   – Rotterdam municipality  : administrative feature ID 'r324431@56'
   – Geometry filter         : ST_INTERSECTS() between administrative boundary
                               and building footprint
   – Surface-area handling   : records without "SURFACE_AREA_SQ_M" are ignored
   – Result columns          : counts & summed surface area for each city,
                               ordered by CLASS / SUBCLASS
--------------------------------------------------------------------------- */

WITH amsterdam AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        COUNT(*)                                AS "AMS_BUILDING_COUNT",
        SUM(b."SURFACE_AREA_SQ_M"::FLOAT)       AS "AMS_TOTAL_SURFACE_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"        b
    JOIN NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"  adm
      ON adm."ID" = 'r47811@69'                                   -- Amsterdam
    WHERE ST_INTERSECTS(adm."GEO_CORDINATES", b."GEO_CORDINATES")
      AND b."SURFACE_AREA_SQ_M" IS NOT NULL
    GROUP BY b."CLASS", b."SUBCLASS"
),
rotterdam AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        COUNT(*)                                AS "RTD_BUILDING_COUNT",
        SUM(b."SURFACE_AREA_SQ_M"::FLOAT)       AS "RTD_TOTAL_SURFACE_SQ_M"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING"        b
    JOIN NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"  adm
      ON adm."ID" = 'r324431@56'                                   -- Rotterdam
    WHERE ST_INTERSECTS(adm."GEO_CORDINATES", b."GEO_CORDINATES")
      AND b."SURFACE_AREA_SQ_M" IS NOT NULL
    GROUP BY b."CLASS", b."SUBCLASS"
)

SELECT
    COALESCE(a."CLASS", r."CLASS")       AS "CLASS",
    COALESCE(a."SUBCLASS", r."SUBCLASS") AS "SUBCLASS",
    a."AMS_BUILDING_COUNT",
    a."AMS_TOTAL_SURFACE_SQ_M",
    r."RTD_BUILDING_COUNT",
    r."RTD_TOTAL_SURFACE_SQ_M"
FROM amsterdam a
FULL OUTER JOIN rotterdam r
  ON a."CLASS" = r."CLASS"
 AND a."SUBCLASS" = r."SUBCLASS"
ORDER BY
    COALESCE(a."CLASS", r."CLASS"),
    COALESCE(a."SUBCLASS", r."SUBCLASS");