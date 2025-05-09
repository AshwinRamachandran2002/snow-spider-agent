/*  Comprehensive side‑by‑side building‑classification comparison  
    for Amsterdam vs. Rotterdam                                           */

WITH city_boundaries AS (   /* collect municipality borders for both cities */
    SELECT
        city,
        ST_UNION_AGG(geom) AS geom
    FROM (
        SELECT
            CASE
                WHEN LOWER(n.value::string) = 'amsterdam' THEN 'Amsterdam'
                WHEN LOWER(n.value::string) = 'rotterdam' THEN 'Rotterdam'
            END                           AS city,
            TRY_TO_GEOGRAPHY(a."GEO_CORDINATES") AS geom
        FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE"  a,
             LATERAL FLATTEN(INPUT => a."NAMES") n
        WHERE a."ADMIN_LEVEL" = '8'                                 -- municipal level
          AND LOWER(n.value::string) IN ('amsterdam','rotterdam')
          AND TRY_TO_GEOGRAPHY(a."GEO_CORDINATES") IS NOT NULL
    )
    GROUP BY city
),

building_city AS (          /* tag every building with the city it lies in */
    SELECT
        b."CLASS",
        b."SUBCLASS",
        cb.city                                         AS city,
        TRY_TO_DOUBLE(b."SURFACE_AREA_SQ_M")            AS surface_area
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN city_boundaries cb
      ON ST_CONTAINS(
             cb.geom ,
             ST_CENTROID( TRY_TO_GEOGRAPHY(b."GEO_CORDINATES") )
         )
    WHERE TRY_TO_GEOGRAPHY(b."GEO_CORDINATES") IS NOT NULL
)

SELECT
    "CLASS",
    "SUBCLASS",

    /* Amsterdam statistics */
    SUM(CASE WHEN city = 'Amsterdam' THEN surface_area ELSE 0 END)
        AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    SUM(CASE WHEN city = 'Amsterdam' THEN 1 ELSE 0 END)
        AS "AMSTERDAM_BUILDING_COUNT",

    /* Rotterdam statistics */
    SUM(CASE WHEN city = 'Rotterdam' THEN surface_area ELSE 0 END)
        AS "ROTTERDAM_TOTAL_SURFACE_SQ_M",
    SUM(CASE WHEN city = 'Rotterdam' THEN 1 ELSE 0 END)
        AS "ROTTERDAM_BUILDING_COUNT"

FROM building_city
GROUP BY "CLASS", "SUBCLASS"
ORDER BY "CLASS" ASC, "SUBCLASS" ASC;