/*  Building‑class comparison between Amsterdam and Rotterdam                    */
/*  --------------------------------------------------------------------------- */
/*  1. city_bounds CTE                                                           */
/*     - Pull the administrative polygons that represent Amsterdam & Rotterdam. */
/*     - The “NAMES” variant is flattened; if *any* of the values equals        */
/*       “amsterdam” or “rotterdam” we keep that polygon and label it “city”.   */
/*  2. Main query                                                                */
/*     - Join every building to the correct city polygon with ST_INTERSECTS.    */
/*     - Aggregate per CLASS / SUBCLASS.                                         */
/*     - Conditional aggregation places Amsterdam and Rotterdam statistics in   */
/*       parallel columns.                                                       */

WITH city_bounds AS (
    SELECT DISTINCT
           CASE
               WHEN LOWER(f.value::string) = 'amsterdam' THEN 'Amsterdam'
               WHEN LOWER(f.value::string) = 'rotterdam' THEN 'Rotterdam'
           END                                                               AS "CITY",
           a."GEO_CORDINATES"
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_ADMINISTRATIVE  a,
         LATERAL FLATTEN(input => a."NAMES")                     f
    WHERE LOWER(f.value::string) IN ('amsterdam','rotterdam')
)

SELECT
    b."CLASS",
    b."SUBCLASS",
    /* Amsterdam statistics */
    ROUND( SUM( CASE WHEN cb."CITY" = 'Amsterdam'
                     THEN COALESCE(TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M"),0)
                END ), 4)                                                   AS "AMSTERDAM_SURFACE_AREA_SQ_M",
    COUNT_IF(cb."CITY" = 'Amsterdam')                                       AS "AMSTERDAM_BUILDING_COUNT",
    /* Rotterdam statistics */
    ROUND( SUM( CASE WHEN cb."CITY" = 'Rotterdam'
                     THEN COALESCE(TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M"),0)
                END ), 4)                                                   AS "ROTTERDAM_SURFACE_AREA_SQ_M",
    COUNT_IF(cb."CITY" = 'Rotterdam')                                       AS "ROTTERDAM_BUILDING_COUNT"
FROM   NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS.V_BUILDING              b
JOIN   city_bounds                                                   cb
       ON ST_INTERSECTS(b."GEO_CORDINATES", cb."GEO_CORDINATES")
GROUP  BY b."CLASS",
          b."SUBCLASS"
ORDER BY b."CLASS" ASC,
         b."SUBCLASS" ASC;