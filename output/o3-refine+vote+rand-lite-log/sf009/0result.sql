WITH
/*--------------------------------------------------------------
  1.  City‑limit polygons built from every admin object whose
      NAMES variant holds “amsterdam” (or “rotterdam”)
--------------------------------------------------------------*/
amsterdam_boundary AS (
    SELECT ST_UNION_AGG(a."GEO_CORDINATES") AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE" a,
         LATERAL FLATTEN(INPUT => a."NAMES") n
    WHERE LOWER(n.value::string) LIKE '%amsterdam%'
      AND a."GEO_CORDINATES" IS NOT NULL
),
rotterdam_boundary AS (
    SELECT ST_UNION_AGG(a."GEO_CORDINATES") AS geom
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_ADMINISTRATIVE" a,
         LATERAL FLATTEN(INPUT => a."NAMES") n
    WHERE LOWER(n.value::string) LIKE '%rotterdam%'
      AND a."GEO_CORDINATES" IS NOT NULL
),
/*--------------------------------------------------------------
  2.  Building‑class statistics inside Amsterdam
--------------------------------------------------------------*/
amsterdam_stats AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")) AS total_surface,
        COUNT(*)                                  AS total_count
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN amsterdam_boundary ab
      ON ST_INTERSECTS(b."GEO_CORDINATES", ab.geom)
    GROUP BY b."CLASS", b."SUBCLASS"
),
/*--------------------------------------------------------------
  3.  Building‑class statistics inside Rotterdam
--------------------------------------------------------------*/
rotterdam_stats AS (
    SELECT
        b."CLASS",
        b."SUBCLASS",
        SUM(TRY_TO_NUMBER(b."SURFACE_AREA_SQ_M")) AS total_surface,
        COUNT(*)                                  AS total_count
    FROM NETHERLANDS_OPEN_MAP_DATA.NETHERLANDS."V_BUILDING" b
    JOIN rotterdam_boundary rb
      ON ST_INTERSECTS(b."GEO_CORDINATES", rb.geom)
    GROUP BY b."CLASS", b."SUBCLASS"
)
/*--------------------------------------------------------------
  4.  Side‑by‑side comparison report
--------------------------------------------------------------*/
SELECT
    COALESCE(a."CLASS",   r."CLASS")    AS "BUILDING_CLASS",
    COALESCE(a."SUBCLASS",r."SUBCLASS") AS "BUILDING_SUBCLASS",
    a.total_surface                     AS "AMSTERDAM_TOTAL_SURFACE_SQ_M",
    a.total_count                       AS "AMSTERDAM_TOTAL_BUILDINGS",
    r.total_surface                     AS "ROTTERDAM_TOTAL_SURFACE_SQ_M",
    r.total_count                       AS "ROTTERDAM_TOTAL_BUILDINGS"
FROM amsterdam_stats a
FULL OUTER JOIN rotterdam_stats r
       ON NVL(a."CLASS",   '') = NVL(r."CLASS",   '')
      AND NVL(a."SUBCLASS",'') = NVL(r."SUBCLASS",'')
ORDER BY "BUILDING_CLASS" ASC NULLS LAST,
         "BUILDING_SUBCLASS" ASC NULLS LAST;