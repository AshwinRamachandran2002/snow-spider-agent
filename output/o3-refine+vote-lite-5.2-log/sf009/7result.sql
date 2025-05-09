/*--------------------------------------------------------------------
  Building‑classification comparison: Amsterdam vs. Rotterdam
--------------------------------------------------------------------*/
WITH city_polygons AS (   /* 1️⃣  collect the municipality polygons */
    SELECT
        CASE
            WHEN LOWER(f.value::string) = 'amsterdam'  THEN 'Amsterdam'
            WHEN LOWER(f.value::string) = 'rotterdam'  THEN 'Rotterdam'
        END                                                        AS CITY ,
        a."GEO_CORDINATES"
    FROM   "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_ADMINISTRATIVE"  a ,
           LATERAL FLATTEN( INPUT => a."NAMES" )                         f
    WHERE  a."ADMIN_LEVEL" = '8'          -- municipality level
      AND  LOWER(f.value::string) IN ('amsterdam','rotterdam')
),
city_union AS (            /* 2️⃣  one unioned geometry per city  */
    SELECT CITY ,
           ST_UNION_AGG("GEO_CORDINATES") AS GEOM
    FROM   city_polygons
    GROUP  BY CITY
),
aggregated AS (            /* 3️⃣  summarise buildings per city / class / subclass */
    SELECT
        b."CLASS" ,
        b."SUBCLASS" ,
        cu.CITY ,
        SUM( TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M") ) AS TOTAL_SURFACE_AREA ,
        COUNT(*)                                   AS NUM_BUILDINGS
    FROM   "NETHERLANDS_OPEN_MAP_DATA"."NETHERLANDS"."V_BUILDING"  b
    JOIN   city_union  cu
           ON ST_WITHIN( b."GEO_CORDINATES" , cu.GEOM )
    GROUP  BY
           b."CLASS" ,
           b."SUBCLASS" ,
           cu.CITY
)

-- 4️⃣  side‑by‑side comparison
SELECT
    "CLASS" ,
    "SUBCLASS" ,
    SUM( CASE WHEN CITY = 'Amsterdam' THEN TOTAL_SURFACE_AREA END ) AS "AMSTERDAM_TOTAL_SURFACE_SQ_M" ,
    SUM( CASE WHEN CITY = 'Amsterdam' THEN NUM_BUILDINGS       END ) AS "AMSTERDAM_NUM_BUILDINGS"     ,
    SUM( CASE WHEN CITY = 'Rotterdam' THEN TOTAL_SURFACE_AREA END ) AS "ROTTERDAM_TOTAL_SURFACE_SQ_M" ,
    SUM( CASE WHEN CITY = 'Rotterdam' THEN NUM_BUILDINGS       END ) AS "ROTTERDAM_NUM_BUILDINGS"
FROM   aggregated
GROUP  BY
       "CLASS" ,
       "SUBCLASS"
ORDER  BY
       "CLASS" ,
       "SUBCLASS";